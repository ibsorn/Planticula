// ============================================================================
// EDGE FUNCTION: identify-seed
// ============================================================================
// Identifies a seed from an image.
// Flow: LLM vision (PlantNet doesn't have a seed-specific endpoint).
//
// Request:  { "image": "<base64>" }
// Response: { success, result: { commonName, scientificName, family,
//           germinationDifficulty, germinationTime, sowingDepth,
//           bestSowingSeason, confidenceScore, description,
//           germinationTips, soilRecommendation, analysisNotes, provider } }
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

    console.log(`[identify-seed] Starting identification (user: ${authResult.user.id})`);

    const content = await callLlmVision({
      prompt: SEED_ID_PROMPT,
      base64Image: image,
      maxTokens: 900,
    });

    const result = parseJsonResponse(content);
    result.provider = "llm-vision";
    result.confidenceScore = numOrNull(result.confidenceScore) ?? 0.6;
    result.germinationTips = stringListOrNull(result.germinationTips) ?? [];
    result.isSuccessful = true;

    console.log("[identify-seed] Done");
    return jsonResponse({ success: true, result });
  } catch (error) {
    console.error("[identify-seed] Error:", error);
    return errorResponse("Internal error");
  }
});

const SEED_ID_PROMPT = `Identifica la semilla de esta imagen y responde SOLO con JSON válido:
{
  "commonName": "Nombre común en español (ej: Tomate, Girasol, Lavanda)",
  "scientificName": "Nombre científico (ej: Solanum lycopersicum)",
  "family": "Familia botánica (ej: Solanaceae)",
  "germinationDifficulty": "easy|moderate|difficult|expert",
  "germinationTime": "veryFast|fast|moderate|slow|verySlow",
  "sowingDepth": "surface|shallow|medium|deep",
  "bestSowingSeason": "spring|summer|autumn|winter|yearRound",
  "confidenceScore": 0.85,
  "description": "Descripción breve de la semilla y la planta que produce en 2-3 frases",
  "germinationTips": ["Consejo 1", "Consejo 2"],
  "soilRecommendation": "Tipo de sustrato recomendado",
  "analysisNotes": "Observación general"
}
Si no puedes identificar la semilla, usa "Semilla no identificada" y confidenceScore bajo (< 0.3).
Responde SOLO con el JSON.`.trim();
