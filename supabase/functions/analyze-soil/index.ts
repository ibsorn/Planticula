// ============================================================================
// EDGE FUNCTION: analyze-soil
// ============================================================================
// Analyzes soil/substrate from an image using LLM vision.
// Replaces the previous stub with real AI analysis.
//
// Request:  { "image": "<base64>" }
// Response: { success, result: { soilType, phLevel, moistureLevel,
//           drainageQuality, organicMatter, recommendations[], analysisNotes } }
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  handleCors, jsonResponse, errorResponse,
  callLlmVision, parseJsonResponse,
  numOrNull, stringListOrNull, requireAuth,
} from "../_shared/ai-helpers.ts";

serve(async (req) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    // Authenticate
    const authResult = await requireAuth(req);
    if (authResult instanceof Response) return authResult;

    const { image } = await req.json();
    if (!image) return errorResponse("Missing 'image' field", 400);

    console.log(`[analyze-soil] Starting analysis (user: ${authResult.user.id})`);

    const content = await callLlmVision({
      prompt: SOIL_PROMPT,
      base64Image: image,
      maxTokens: 800,
    });

    const data = parseJsonResponse(content);

    const result = {
      soilType: String(data.soilType ?? "unknown"),
      phLevel: numOrNull(data.phLevel) ?? 7.0,
      moistureLevel: String(data.moistureLevel ?? "optimal"),
      drainageQuality: String(data.drainageQuality ?? "moderate"),
      organicMatter: String(data.organicMatter ?? "moderate"),
      recommendations: stringListOrNull(data.recommendations) ?? [],
      analysisNotes: data.analysisNotes ? String(data.analysisNotes) : null,
      provider: "llm-vision",
      isSuccessful: true,
    };

    console.log("[analyze-soil] Done");
    return jsonResponse({ success: true, result });
  } catch (error) {
    console.error("[analyze-soil] Error:", error);
    return errorResponse("Internal error");
  }
});

const SOIL_PROMPT = `Analiza esta imagen de sustrato/tierra de planta y responde SOLO con JSON válido:
{
  "soilType": "sandy|clay|silty|loamy|peaty|chalky|rocky|pottingMix|cactusMix|orchidMix|unknown",
  "phLevel": 6.5,
  "moistureLevel": "veryDry|dry|slightlyDry|optimal|moist|wet|waterlogged",
  "drainageQuality": "excellent|good|moderate|poor|veryPoor",
  "organicMatter": "veryLow|low|moderate|high|veryHigh",
  "recommendations": ["Recomendación 1", "Recomendación 2"],
  "analysisNotes": "Notas generales sobre el sustrato"
}
Si no puedes determinar un campo, usa el valor más neutro (ej: "unknown", 7.0, "optimal").
Responde SOLO con el JSON.`.trim();
