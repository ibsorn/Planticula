// ============================================================================
// EDGE FUNCTION: diagnose-disease
// ============================================================================
// Diagnoses plant health problems from an image using LLM vision.
//
// Request:  { "image": "<base64>" }
// Response: { success, result: { diagnosisType, problemName, scientificName,
//           severity, confidenceScore, description, remedies[],
//           preventionTips, analysisNotes, provider } }
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  handleCors, jsonResponse, errorResponse,
  callLlmVision, parseJsonResponse,
  numOrNull,
} from "../_shared/ai-helpers.ts";

interface Remedy {
  title: string;
  description: string;
  type: string;
  ingredients: string | null;
  instructions: string;
  effectiveness: string;
}

serve(async (req) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const { image } = await req.json();
    if (!image) return errorResponse("Missing 'image' field", 400);

    console.log("[diagnose-disease] Starting diagnosis");

    const content = await callLlmVision({
      prompt: DISEASE_PROMPT,
      base64Image: image,
      maxTokens: 1200,
    });

    const data = parseJsonResponse(content);
    const rawRemedies = data.remedies;
    const remedies: Remedy[] = [];

    if (Array.isArray(rawRemedies)) {
      for (const r of rawRemedies) {
        if (r && typeof r === "object") {
          remedies.push({
            title: String(r.title ?? ""),
            description: String(r.description ?? ""),
            type: String(r.type ?? "homemade"),
            ingredients: r.ingredients ? String(r.ingredients) : null,
            instructions: String(r.instructions ?? ""),
            effectiveness: String(r.effectiveness ?? "moderate"),
          });
        }
      }
    }

    const result = {
      diagnosisType: String(data.diagnosisType ?? "unknown"),
      problemName: String(data.problemName ?? "Desconocido"),
      scientificName: data.scientificName ? String(data.scientificName) : null,
      severity: String(data.severity ?? "medium"),
      confidenceScore: numOrNull(data.confidenceScore) ?? 0.7,
      description: data.description ? String(data.description) : null,
      remedies,
      preventionTips: data.preventionTips ? String(data.preventionTips) : null,
      analysisNotes: data.analysisNotes ? String(data.analysisNotes) : null,
      provider: "llm-vision",
      isSuccessful: true,
    };

    console.log("[diagnose-disease] Done");
    return jsonResponse({ success: true, result });
  } catch (error) {
    console.error("[diagnose-disease] Error:", error);
    return errorResponse(error.message || "Internal error");
  }
});

const DISEASE_PROMPT = `Analiza esta imagen de planta y diagnostica cualquier problema de salud visible. Responde SOLO con JSON válido:
{
  "diagnosisType": "pest|disease|deficiency|environmentalStress|healthy|unknown",
  "problemName": "Nombre del problema en español",
  "scientificName": "Nombre científico si aplica, o null",
  "severity": "low|medium|high|critical",
  "confidenceScore": 0.85,
  "description": "Descripción detallada del problema en 2-3 frases",
  "remedies": [
    {
      "title": "Título del remedio",
      "description": "Descripción",
      "type": "homemade|organic|chemical",
      "ingredients": "Ingredientes o null",
      "instructions": "Instrucciones de aplicación",
      "effectiveness": "low|moderate|high|veryHigh"
    }
  ],
  "preventionTips": "Consejos para prevenir el problema",
  "analysisNotes": "Observaciones generales"
}
Reglas:
- diagnosisType: pest=insectos, disease=hongos/bacterias, deficiency=carencias, environmentalStress=luz/temp/humedad, healthy=sana
- remedies: SIEMPRE primero remedios caseros (type: "homemade") con cosas de casa (agua, jabón, ajo, bicarbonato...). Luego orgánicos. 2-4 remedios.
- Si está sana: problemName="Planta sana", severity="low", remedies=[]
Responde SOLO con el JSON.`.trim();
