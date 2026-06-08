// ============================================================================
// EDGE FUNCTION: analyze-soil
// ============================================================================
// Analiza imágenes de sustrato/suelo y devuelve resultados
// Flujo: Recibe analysis_id → obtiene imagen de Storage → analiza → guarda resultados
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

// Tipos de datos
interface SoilAnalysisRequest {
  analysis_id: string;
}

interface SoilAnalysisResult {
  soil_type: string;
  ph_level: number;
  moisture_level: string;
  drainage_quality: string;
  organic_matter: string;
  recommendations: string[];
  notes?: string;
}

// Variables de entorno
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// ============================================================================
// HANDLER PRINCIPAL
// ============================================================================

serve(async (req) => {
  // CORS headers
  const headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "apikey, Authorization, Content-Type",
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers });
  }

  try {
    // Parse request body
    const { analysis_id } = await req.json() as SoilAnalysisRequest;

    if (!analysis_id) {
      return new Response(
        JSON.stringify({ error: "analysis_id es requerido" }),
        { status: 400, headers }
      );
    }

    console.log(`🔬 Iniciando análisis de sustrato: ${analysis_id}`);

    // Crear cliente de Supabase con service role
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Obtener información del análisis
    const { data: analysis, error: fetchError } = await supabase
      .from("soil_analyses")
      .select("*")
      .eq("id", analysis_id)
      .single();

    if (fetchError || !analysis) {
      console.error("❌ Error obteniendo análisis:", fetchError);
      await markError(supabase, analysis_id, "No se encontró el análisis solicitado");
      return new Response(
        JSON.stringify({ error: "Análisis no encontrado" }),
        { status: 404, headers }
      );
    }

    // 2. Actualizar estado a "processing"
    await supabase
      .from("soil_analyses")
      .update({ status: "processing", updated_at: new Date().toISOString() })
      .eq("id", analysis_id);

    console.log(`📥 Análisis encontrado, imagen: ${analysis.image_url}`);

    // 3. Descargar imagen desde Storage
    const imagePath = extractPathFromUrl(analysis.image_url);
    if (!imagePath) {
      throw new Error("No se pudo extraer la ruta de la imagen");
    }

    const { data: imageData, error: imageError } = await supabase
      .storage
      .from("soil-images")
      .download(imagePath);

    if (imageError || !imageData) {
      throw new Error(`Error descargando imagen: ${imageError?.message || "Unknown"}`);
    }

    console.log(`✅ Imagen descargada: ${imageData.size} bytes`);

    // 4. ANÁLISIS DE LA IMAGEN
    // Aquí es donde integrarías tu servicio de IA/ML
    // Por ahora usamos un análisis simulado/demo
    const result = await performSoilAnalysis(imageData);

    console.log(`🔬 Análisis completado:`, result);

    // 5. Guardar resultados en la base de datos
    const { error: updateError } = await supabase.rpc("update_soil_analysis_results", {
      p_analysis_id: analysis_id,
      p_soil_type: result.soil_type,
      p_ph_level: result.ph_level,
      p_moisture_level: result.moisture_level,
      p_drainage_quality: result.drainage_quality,
      p_organic_matter: result.organic_matter,
      p_recommendations: result.recommendations,
      p_notes: result.notes,
    });

    if (updateError) {
      throw new Error(`Error guardando resultados: ${updateError.message}`);
    }

    console.log(`✅ Resultados guardados para análisis ${analysis_id}`);

    return new Response(
      JSON.stringify({
        success: true,
        analysis_id,
        result,
      }),
      { status: 200, headers }
    );

  } catch (error) {
    console.error("❌ Error en análisis:", error);

    // Marcar como error en la BD
    try {
      const supabase = createClient(supabaseUrl, supabaseServiceKey);
      await markError(supabase, analysis_id, error.message || "Error desconocido");
    } catch (e) {
      console.error("Error marcando estado de error:", e);
    }

    return new Response(
      JSON.stringify({
        error: error.message || "Error interno del servidor",
      }),
      { status: 500, headers }
    );
  }
});

// ============================================================================
// FUNCIONES AUXILIARES
// ============================================================================

/**
 * Realiza el análisis del sustrato
 * TODO: Reemplazar con integración real de IA/ML (OpenAI Vision, Google Vision, etc.)
 */
async function performSoilAnalysis(imageData: Blob): Promise<SoilAnalysisResult> {
  // Simulación de análisis - En producción esto llamaría a una API de IA

  // Aquí tienes opciones para implementar el análisis real:
  //
  // OPCIÓN 1: OpenAI GPT-4 Vision
  // - Convierte la imagen a base64
  // - Envía a GPT-4 con prompt específico para análisis de sustrato
  // - Parsea la respuesta
  //
  // OPCIÓN 2: Google Cloud Vision API
  // - Label detection para identificar materiales
  // - Image properties para colores (indican tipo de sustrato)
  //
  // OPCIÓN 3: AWS Rekognition
  // - Similar a Google Vision
  //
  // OPCIÓN 4: Modelo propio (TensorFlow.js)
  // - Entrena modelo con fotos de diferentes tipos de sustrato
  // - Mayor control pero requiere dataset de entrenamiento

  console.log(`🤖 Analizando imagen de ${imageData.size} bytes...`);

  // Simulación: Esperar 2 segundos como si estuviera procesando
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Análisis simulado aleatorio para demo
  const soilTypes = ["loamy", "sandy", "clay", "pottingMix", "peaty"];
  const moistureLevels = ["optimal", "slightlyDry", "moist", "dry"];
  const drainageLevels = ["good", "excellent", "moderate", "poor"];
  const nutrientLevels = ["moderate", "high", "low", "veryHigh"];

  const randomSoilType = soilTypes[Math.floor(Math.random() * soilTypes.length)];
  const randomPh = 5.5 + Math.random() * 3; // pH entre 5.5 y 8.5

  return {
    soil_type: randomSoilType,
    ph_level: parseFloat(randomPh.toFixed(1)),
    moisture_level: moistureLevels[Math.floor(Math.random() * moistureLevels.length)],
    drainage_quality: drainageLevels[Math.floor(Math.random() * drainageLevels.length)],
    organic_matter: nutrientLevels[Math.floor(Math.random() * nutrientLevels.length)],
    recommendations: generateRecommendations(randomSoilType, randomPh),
    notes: "Análisis completado mediante Edge Function (modo demo)",
  };
}

/**
 * Genera recomendaciones basadas en el tipo de sustrato y pH
 */
function generateRecommendations(soilType: string, ph: number): string[] {
  const recommendations: string[] = [];

  // Recomendaciones por tipo de sustrato
  switch (soilType) {
    case "sandy":
      recommendations.push("Añadir materia orgánica para mejorar retención de agua");
      recommendations.push("Riego más frecuente pero en menor cantidad");
      break;
    case "clay":
      recommendations.push("Mejorar drenaje añadiendo perlita o arena gruesa");
      recommendations.push("Evitar riegos excesivos para prevenir encharcamiento");
      break;
    case "loamy":
      recommendations.push("Excelente sustrato, mantener cuidado regular");
      break;
    case "pottingMix":
      recommendations.push("Renovar cada 1-2 años según el tipo de planta");
      break;
    case "peaty":
      recommendations.push("Ideal para plantas ácidas como helechos y arándanos");
      recommendations.push("Controlar pH si se usan para plantas no ácidas");
      break;
  }

  // Recomendaciones por pH
  if (ph < 6.0) {
    recommendations.push("pH ligeramente ácido - Adecuado para la mayoría de plantas de interior");
  } else if (ph > 7.5) {
    recommendations.push("Considerar acidificar el sustrato para plantas sensibles");
  }

  // Recomendaciones generales
  recommendations.push("Monitorear humedad antes de cada riego");
  recommendations.push("Fertilizar según las necesidades específicas de la planta");

  return recommendations;
}

/**
 * Extrae el path del bucket desde una URL pública de Storage
 */
function extractPathFromUrl(url: string): string | null {
  try {
    // La URL tiene formato: https://project.supabase.co/storage/v1/object/public/soil-images/path
    const urlObj = new URL(url);
    const pathParts = urlObj.pathname.split("/");

    // Buscar el índice de 'soil-images' y tomar todo después
    const bucketIndex = pathParts.indexOf("soil-images");
    if (bucketIndex >= 0 && bucketIndex < pathParts.length - 1) {
      return pathParts.slice(bucketIndex + 1).join("/");
    }
    return null;
  } catch (e) {
    console.error("Error extrayendo path de URL:", e);
    return null;
  }
}

/**
 * Marca un análisis como error
 */
async function markError(
  supabase: SupabaseClient,
  analysisId: string,
  errorMessage: string
): Promise<void> {
  await supabase.rpc("mark_soil_analysis_error", {
    p_analysis_id: analysisId,
    p_error_message: errorMessage,
  });
}
