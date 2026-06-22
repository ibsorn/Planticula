// ============================================================================
// EDGE FUNCTION: identify-plant
// ============================================================================
// Identifies a plant from an image.
// Flow: PlantNet API (400k+ species) → LLM vision fallback → care info cache.
//
// Request:  { "image": "<base64>", "includeVisualMeta": true|false }
// Response: { success, commonName, scientificName, family, confidenceScore,
//             careLevel, wateringFrequency, lightRequirement, humidityRequirement,
//             toxicToPets, toxicToHumans, description, characteristics,
//             careTips, analysisNotes, provider,
//             growthStage?, potSize?, environment? }
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders, handleCors, jsonResponse, errorResponse,
  callLlmVision, callLlmText, callPlantNet,
  parseJsonResponse, numOrNull, boolOrNull, stringListOrNull,
  getEnvOrDefault,
} from "../_shared/ai-helpers.ts";

const CONFIDENCE_THRESHOLD = 0.7;

serve(async (req) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const { image, includeVisualMeta } = await req.json();
    if (!image) return errorResponse("Missing 'image' field", 400);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    console.log("[identify-plant] Starting identification");

    // ── 1. Try PlantNet first ──────────────────────────────────────────
    let plantNetResult = null;
    try {
      plantNetResult = await callPlantNet(image);
      if (plantNetResult) {
        console.log(`[identify-plant] PlantNet: ${plantNetResult.scientificName} (${plantNetResult.score})`);
      }
    } catch (e) {
      console.warn(`[identify-plant] PlantNet failed: ${e.message}`);
    }

    // ── 2. Build result from PlantNet or fall back to LLM vision ──────
    let result: Record<string, unknown>;

    if (plantNetResult && plantNetResult.score >= CONFIDENCE_THRESHOLD) {
      // PlantNet succeeded with high confidence — get care info from cache/LLM
      const careInfo = await getOrCreateCareInfo(
        supabase,
        plantNetResult.scientificName,
      );

      result = {
        commonName: plantNetResult.commonName ?? plantNetResult.scientificName,
        scientificName: plantNetResult.scientificName,
        family: plantNetResult.family,
        confidenceScore: plantNetResult.score,
        provider: "plantnet",
        ...careInfo,
      };
    } else {
      // PlantNet failed or low confidence — use LLM vision
      console.log("[identify-plant] Using LLM vision fallback");
      const llmContent = await callLlmVision({
        prompt: PLANT_ID_PROMPT,
        base64Image: image,
        maxTokens: 1000,
      });
      result = parseJsonResponse(llmContent);
      result.provider = "llm-vision";
      result.confidenceScore = numOrNull(result.confidenceScore) ?? 0.6;
    }

    // ── 3. Visual metadata (growthStage, potSize, environment) ────────
    if (includeVisualMeta) {
      try {
        const visualContent = await callLlmVision({
          prompt: VISUAL_META_PROMPT,
          base64Image: image,
          maxTokens: 500,
        });
        const visual = parseJsonResponse(visualContent);
        result.environment = visual.environment ?? "indoor";
        result.growthStage = visual.growthStage ?? "development";
        result.potSize = visual.potSize ?? "medium";
        result.environmentConfidence = numOrNull(visual.environmentConfidence) ?? 0.6;
        result.growthStageConfidence = numOrNull(visual.growthStageConfidence) ?? 0.6;
        result.potSizeConfidence = numOrNull(visual.potSizeConfidence) ?? 0.5;
      } catch (e) {
        console.warn(`[identify-plant] Visual meta failed: ${e.message}`);
        result.environment = "indoor";
        result.growthStage = "development";
        result.potSize = "medium";
      }
    }

    // ── 4. Normalize fields ───────────────────────────────────────────
    result.toxicToPets = boolOrNull(result.toxicToPets);
    result.toxicToHumans = boolOrNull(result.toxicToHumans);
    result.characteristics = stringListOrNull(result.characteristics) ?? [];
    result.careTips = stringListOrNull(result.careTips) ?? [];
    result.isSuccessful = true;

    console.log(`[identify-plant] Done via ${result.provider}`);
    return jsonResponse({ success: true, result });
  } catch (error) {
    console.error("[identify-plant] Error:", error);
    return errorResponse(error.message || "Internal error");
  }
});

// ============================================================================
// CARE INFO CACHE
// ============================================================================

async function getOrCreateCareInfo(
  supabase: ReturnType<typeof createClient>,
  scientificName: string,
): Promise<Record<string, unknown>> {
  // Check cache
  const { data: cached } = await supabase
    .from("ai_care_cache")
    .select("care_info")
    .eq("scientific_name", scientificName)
    .maybeSingle();

  if (cached?.care_info) {
    console.log(`[identify-plant] Care info from cache: ${scientificName}`);
    // Increment hit count
    try {
      await supabase.rpc("increment_care_cache_hit", {
        p_scientific_name: scientificName,
      });
    } catch (e) {
      console.warn(`[identify-plant] Hit count increment failed: ${e.message}`);
    }
    return cached.care_info as Record<string, unknown>;
  }

  // Not cached — generate via LLM text
  console.log(`[identify-plant] Generating care info for: ${scientificName}`);
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

  // Save to cache
  try {
    await supabase
      .from("ai_care_cache")
      .upsert({
        scientific_name: scientificName,
        care_info: careInfo,
        hit_count: 1,
      });
  } catch (e) {
    console.warn(`[identify-plant] Cache save failed: ${e.message}`);
  }

  return careInfo;
}

// ============================================================================
// PROMPTS
// ============================================================================

const PLANT_ID_PROMPT = `Identifica la planta de esta imagen y responde SOLO con JSON válido:
{
  "commonName": "Nombre común en español (ej: Pothos, Monstera, Cactus)",
  "scientificName": "Nombre científico (ej: Epipremnum aureum)",
  "family": "Familia botánica (ej: Araceae)",
  "careLevel": "easy|moderate|difficult|expert",
  "wateringFrequency": "veryRare|rare|moderate|frequent|veryFrequent",
  "lightRequirement": "deepShade|shade|indirectLight|brightIndirect|directLight|fullSun",
  "humidityRequirement": "veryLow|low|moderate|high|veryHigh",
  "toxicToPets": false,
  "toxicToHumans": false,
  "confidenceScore": 0.85,
  "description": "Descripción breve de la planta en 2-3 frases",
  "characteristics": ["Característica 1", "Característica 2"],
  "careTips": ["Consejo de cuidado 1", "Consejo de cuidado 2"],
  "analysisNotes": "Observación general sobre la planta"
}
Si no puedes identificar la planta, usa "Planta no identificada" en commonName y confidenceScore bajo (< 0.3).
Responde SOLO con el JSON, sin texto adicional.`.trim();

const VISUAL_META_PROMPT = `Analiza esta imagen de planta y responde SOLO con JSON válido:
{
  "environment": "indoor|outdoor",
  "growthStage": "germination|seedling|development|mature|flowering",
  "potSize": "extra_small|small|medium|large|extra_large",
  "environmentConfidence": 0.75,
  "growthStageConfidence": 0.80,
  "potSizeConfidence": 0.65
}
- environment: "indoor" si parece planta de interior, "outdoor" si parece de exterior
- growthStage: germination=recién germinada, seedling=plántula, development=crecimiento activo, mature=madura, flowering=floración
- potSize: extra_small=~5cm, small=~10cm, medium=~15cm, large=~25cm, extra_large=35cm+
Responde SOLO con el JSON.`.trim();
