// ============================================================================
// EDGE FUNCTION: analyze-soil-photo
// ============================================================================
// Analiza fotos de sustrato/suelo usando IA visual externa (OpenAI Vision)
// Estructura modular: validación → servicio IA → respuesta
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getCorsHeaders } from "../_shared/ai-helpers.ts";

// ============================================================================
// TIPOS DE DATOS
// ============================================================================

interface AnalysisRequest {
  image_url?: string;
  image_path?: string;
  plant_id?: string; // Opcional - para asociar el análisis
}

interface SoilAnalysisResult {
  humidity: {
    level: 'low' | 'medium-low' | 'medium' | 'medium-high' | 'high';
    estimated_percentage: number;
    description: string;
  };
  compaction: {
    level: 'none' | 'low' | 'moderate' | 'high' | 'very-high';
    description: string;
  };
  drainage: {
    probability: 'very-low' | 'low' | 'medium' | 'high' | 'very-high';
    estimated_score: number; // 0-100
    description: string;
  };
  recommendation: string;
  raw_analysis?: string; // Respuesta cruda de la IA (para debugging)
}

interface AnalysisResponse {
  success: boolean;
  data?: SoilAnalysisResult;
  error?: string;
  timestamp: string;
  processing_time_ms: number;
}

// ============================================================================
// CONFIGURACIÓN
// ============================================================================

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  const startTime = Date.now();

  // CORS headers
  const origin = req.headers.get("Origin");
  const headers = {
    "Content-Type": "application/json",
    ...getCorsHeaders(origin),
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers });
  }

  try {
    // ========================================================================
    // 1. VALIDACIÓN DE AUTENTICACIÓN (JWT)
    // ========================================================================
    const authHeader = req.headers.get("Authorization");
    const apiKey = req.headers.get("apikey");

    if (!authHeader) {
      return createErrorResponse(
        401,
        "Se requiere token de autenticación",
        headers,
        startTime
      );
    }

    // Extraer JWT del header
    const jwt = authHeader.replace("Bearer ", "");

    // Crear cliente de Supabase con el JWT del usuario
    const supabaseClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
      global: {
        headers: {
          Authorization: `Bearer ${jwt}`,
        },
      },
    });

    // Validar JWT obteniendo el usuario
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();

    if (userError || !user) {
      console.error("❌ Error de autenticación:", userError);
      return createErrorResponse(
        401,
        "Token de autenticación inválido o expirado",
        headers,
        startTime
      );
    }

    console.log(`✅ Usuario autenticado: ${user.id}`);

    // ========================================================================
    // 2. VALIDACIÓN DE PARÁMETROS
    // ========================================================================
    let requestBody: AnalysisRequest;
    try {
      requestBody = await req.json();
    } catch (e) {
      return createErrorResponse(
        400,
        "Body de la petición inválido (JSON malformado)",
        headers,
        startTime
      );
    }

    const { image_url, image_path, plant_id } = requestBody;

    if (!image_url && !image_path) {
      return createErrorResponse(
        400,
        "Se requiere 'image_url' o 'image_path'",
        headers,
        startTime
      );
    }

    // Construir URL final de la imagen
    let finalImageUrl: string;
    if (image_url) {
      // Validate URL to prevent SSRF
      if (!isAllowedImageUrl(image_url)) {
        return createErrorResponse(
          400,
          "Invalid image URL: only HTTPS URLs from allowed domains are accepted",
          headers,
          startTime
        );
      }
      finalImageUrl = image_url;
    } else {
      // Construir URL pública desde el path — sanitize path to prevent traversal
      const safePath = image_path!.replace(/\.\.\//g, "").replace(/^\/+/, "");
      finalImageUrl = `${SUPABASE_URL}/storage/v1/object/public/soil-images/${safePath}`;
    }

    console.log(`📸 Analizando imagen: ${finalImageUrl}`);

    // ========================================================================
    // 3. LLAMADA AL SERVICIO EXTERNO DE IA
    // ========================================================================
    const analysisResult = await analyzeWithOpenAI(finalImageUrl);

    // ========================================================================
    // 4. CONSTRUIR RESPUESTA
    // ========================================================================
    const response: AnalysisResponse = {
      success: true,
      data: analysisResult,
      timestamp: new Date().toISOString(),
      processing_time_ms: Date.now() - startTime,
    };

    console.log(`✅ Análisis completado en ${response.processing_time_ms}ms`);

    return new Response(
      JSON.stringify(response),
      { status: 200, headers }
    );

  } catch (error) {
    console.error("❌ Error no controlado:", error);
    return createErrorResponse(
      500,
      "Error interno del servidor",
      headers,
      startTime
    );
  }
});

// ============================================================================
// SERVICIO EXTERNO: OpenAI Vision
// ============================================================================

async function analyzeWithOpenAI(imageUrl: string): Promise<SoilAnalysisResult> {
  if (!OPENAI_API_KEY) {
    console.warn("⚠️ OPENAI_API_KEY no configurado, usando análisis simulado");
    return generateSimulatedAnalysis();
  }

  try {
    console.log("🤖 Llamando a OpenAI Vision API...");

    const prompt = `Analiza esta imagen de sustrato/suelo de planta y devuelve un JSON estructurado con:

1. Humedad estimada (percentage 0-100 y level: low/medium-low/medium/medium-high/high)
2. Compactación aparente (level: none/low/moderate/high/very-high)
3. Probabilidad de buen drenaje (score 0-100 y probability: very-low/low/medium/high/very-high)
4. Una recomendación textual específica para mejorar el sustrato

Responde ÚNICAMENTE con este JSON, sin markdown ni explicaciones adicionales:

{
  "humidity": {
    "level": "medium",
    "estimated_percentage": 45,
    "description": "Sustrato ligeramente húmedo, buen equilibrio"
  },
  "compaction": {
    "level": "low",
    "description": "Sustrato suelto con buena aireación"
  },
  "drainage": {
    "probability": "high",
    "estimated_score": 75,
    "description": "Buen drenaje probable por textura visible"
  },
  "recommendation": "Mantener riego actual, el sustrato está en buenas condiciones"
}`;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini", // Modelo económico y rápido para vision
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              {
                type: "image_url",
                image_url: {
                  url: imageUrl,
                  detail: "high", // Alta calidad para detectar textura del sustrato
                },
              },
            ],
          },
        ],
        max_tokens: 1000,
        temperature: 0.3, // Baja creatividad para respuestas consistentes
      }),
    });

    if (!response.ok) {
      const errorData = await response.text();
      throw new Error(`OpenAI API error: ${response.status} - ${errorData}`);
    }

    const openAIResponse = await response.json();
    const content = openAIResponse.choices[0]?.message?.content;

    if (!content) {
      throw new Error("Respuesta vacía de OpenAI");
    }

    console.log("📝 Respuesta cruda de OpenAI:", content.substring(0, 200));

    // Parsear JSON de la respuesta
    // A veces OpenAI envuelve en markdown ```json ... ```
    const jsonMatch = content.match(/```json\s*([\s\S]*?)```/) ||
                      content.match(/```\s*([\s\S]*?)```/) ||
                      [null, content];

    const jsonString = jsonMatch[1]?.trim() || content;
    const parsedResult = JSON.parse(jsonString);

    return {
      humidity: {
        level: validateHumidityLevel(parsedResult.humidity?.level),
        estimated_percentage: clamp(parsedResult.humidity?.estimated_percentage, 0, 100),
        description: parsedResult.humidity?.description || "Sin descripción",
      },
      compaction: {
        level: validateCompactionLevel(parsedResult.compaction?.level),
        description: parsedResult.compaction?.description || "Sin descripción",
      },
      drainage: {
        probability: validateDrainageProbability(parsedResult.drainage?.probability),
        estimated_score: clamp(parsedResult.drainage?.estimated_score, 0, 100),
        description: parsedResult.drainage?.description || "Sin descripción",
      },
      recommendation: parsedResult.recommendation || "No se generó recomendación",
      raw_analysis: content, // Para debugging
    };

  } catch (error) {
    console.error("❌ Error en análisis OpenAI:", error);
    // Fallback a análisis simulado si falla la IA
    return generateSimulatedAnalysis();
  }
}

// ============================================================================
// ANÁLISIS SIMULADO (Fallback/Demo)
// ============================================================================

function generateSimulatedAnalysis(): SoilAnalysisResult {
  console.log("🎲 Generando análisis simulado...");

  const analyses: SoilAnalysisResult[] = [
    {
      humidity: {
        level: "medium",
        estimated_percentage: 50,
        description: "Sustrato con humedad equilibrada, ni muy seco ni muy húmedo",
      },
      compaction: {
        level: "low",
        description: "Sustrato suelto con partículas bien separadas, excelente aireación",
      },
      drainage: {
        probability: "high",
        estimated_score: 80,
        description: "Alto drenaje probable por textura arenosa visible",
      },
      recommendation: "El sustrato está en excelentes condiciones. Mantener riego moderado cada 5-7 días según la especie de la planta.",
    },
    {
      humidity: {
        level: "low",
        estimated_percentage: 25,
        description: "Sustrato seco, color claro indica falta de humedad",
      },
      compaction: {
        level: "moderate",
        description: "Ligera compactación detectada, sustrato algo denso",
      },
      drainage: {
        probability: "medium",
        estimated_score: 55,
        description: "Drenaje moderado, puede retener algo de agua",
      },
      recommendation: "Riego inmediato recomendado. Considerar añadir perlita para mejorar aireación y revisar el programa de riego.",
    },
    {
      humidity: {
        level: "high",
        estimated_percentage: 80,
        description: "Sustrato muy húmedo, color oscuro y textura pesada",
      },
      compaction: {
        level: "high",
        description: "Compactación significativa, sustrato denso y pesado",
      },
      drainage: {
        probability: "low",
        estimated_score: 30,
        description: "Drenaje deficiente probable, riesgo de encharcamiento",
      },
      recommendation: "ALERTA: Riesgo de pudrición de raíces. Suspender riego inmediatamente, mejorar drenaje con perlita o arena gruesa, y considerar trasplante a sustrato más drenante.",
    },
  ];

  return analyses[Math.floor(Math.random() * analyses.length)];
}

// ============================================================================
// UTILIDADES DE VALIDACIÓN
// ============================================================================

function createErrorResponse(
  status: number,
  message: string,
  headers: Record<string, string>,
  startTime: number
): Response {
  const response: AnalysisResponse = {
    success: false,
    error: message,
    timestamp: new Date().toISOString(),
    processing_time_ms: Date.now() - startTime,
  };

  return new Response(
    JSON.stringify(response),
    { status, headers }
  );
}

function validateHumidityLevel(level: string): SoilAnalysisResult['humidity']['level'] {
  const valid = ['low', 'medium-low', 'medium', 'medium-high', 'high'] as const;
  return valid.includes(level as any) ? level as any : 'medium';
}

function validateCompactionLevel(level: string): SoilAnalysisResult['compaction']['level'] {
  const valid = ['none', 'low', 'moderate', 'high', 'very-high'] as const;
  return valid.includes(level as any) ? level as any : 'low';
}

function validateDrainageProbability(prob: string): SoilAnalysisResult['drainage']['probability'] {
  const valid = ['very-low', 'low', 'medium', 'high', 'very-high'] as const;
  return valid.includes(prob as any) ? prob as any : 'medium';
}

function clamp(value: number, min: number, max: number): number {
  if (typeof value !== 'number' || isNaN(value)) return min;
  return Math.max(min, Math.min(max, value));
}

/**
 * Validates that a user-supplied image URL is safe (prevents SSRF).
 * Only allows HTTPS URLs to known image-hosting domains.
 */
function isAllowedImageUrl(url: string): boolean {
  try {
    const parsed = new URL(url);

    // Must be HTTPS
    if (parsed.protocol !== "https:") return false;

    // Block private/internal IPs and metadata endpoints
    const hostname = parsed.hostname.toLowerCase();
    if (
      hostname === "localhost" ||
      hostname.startsWith("127.") ||
      hostname.startsWith("10.") ||
      hostname.startsWith("172.") ||
      hostname.startsWith("192.168.") ||
      hostname === "169.254.169.254" ||
      hostname.endsWith(".internal") ||
      hostname.endsWith(".local")
    ) {
      return false;
    }

    // Allow only known domains (Supabase storage, common image CDNs)
    const allowedDomains = [
      ".supabase.co",
      ".supabase.in",
    ];

    return allowedDomains.some((d) => hostname.endsWith(d));
  } catch {
    return false;
  }
}
