// ============================================================================
// EDGE FUNCTION: generate-care-info
// ============================================================================
// Generates or retrieves cached care information for a plant species.
// Uses LLM text (no image — much cheaper) and caches in ai_care_cache table.
//
// Request:  { "scientificName": "Epipremnum aureum" }
// Response: { success, careInfo: { careLevel, wateringFrequency, ... }, cached }
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  handleCors, jsonResponse, errorResponse,
  callLlmText, parseJsonResponse, requireAuth,
} from "../_shared/ai-helpers.ts";

serve(async (req) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    // Authenticate
    const authResult = await requireAuth(req);
    if (authResult instanceof Response) return authResult;

    const { scientificName } = await req.json();
    if (!scientificName) return errorResponse("Missing 'scientificName'", 400);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // 1. Check cache
    const { data: cached } = await supabase
      .from("ai_care_cache")
      .select("care_info")
      .eq("scientific_name", scientificName)
      .maybeSingle();

    if (cached?.care_info) {
      console.log(`[generate-care-info] Cache hit: ${scientificName}`);
      try {
        await supabase.rpc("increment_care_cache_hit", {
          p_scientific_name: scientificName,
        });
      } catch (e) {
        console.warn(`[generate-care-info] Hit count increment failed: ${e.message}`);
      }
      return jsonResponse({
        success: true,
        careInfo: cached.care_info,
        cached: true,
      });
    }

    // 2. Generate via LLM text
    console.log(`[generate-care-info] Generating for: ${scientificName}`);
    const content = await callLlmText({
      prompt: `Eres un experto botánico. Para la planta "${scientificName}", responde SOLO con JSON válido:
{
  "careLevel": "easy|moderate|difficult|expert",
  "wateringFrequency": "veryRare|rare|moderate|frequent|veryFrequent",
  "lightRequirement": "deepShade|shade|indirectLight|brightIndirect|directLight|fullSun",
  "humidityRequirement": "veryLow|low|moderate|high|veryHigh",
  "toxicToPets": false,
  "toxicToHumans": false,
  "description": "Descripción breve en español (2-3 frases)",
  "characteristics": ["Característica 1", "Característica 2"],
  "careTips": ["Consejo 1", "Consejo 2"]
}`,
      maxTokens: 600,
    });

    const careInfo = parseJsonResponse(content);

    // 3. Save to cache
    try {
      await supabase
        .from("ai_care_cache")
        .upsert({
          scientific_name: scientificName,
          care_info: careInfo,
          hit_count: 1,
        });
    } catch (e) {
      console.warn(`[generate-care-info] Cache save failed: ${e.message}`);
    }

    console.log("[generate-care-info] Done (new cache entry)");
    return jsonResponse({ success: true, careInfo, cached: false });
  } catch (error) {
    console.error("[generate-care-info] Error:", error);
    return errorResponse("Internal error");
  }
});
