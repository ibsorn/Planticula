// ============================================================================
// EDGE FUNCTION: watering-recommendation
// ============================================================================
// Genera recomendaciones de riego inteligentes basadas en:
// - Especie de la planta (consultada desde BD)
// - Ubicación geográfica de la planta
// - Previsión meteorológica (OpenWeather One Call API)
// - Condiciones actuales y próximas 24h/72h
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getCorsHeaders } from "../_shared/ai-helpers.ts";

// ============================================================================
// TIPOS DE DATOS
// ============================================================================

interface WateringRequest {
  plant_id: string;
}

interface PlantData {
  id: string;
  name: string;
  species: string;
  location_lat?: number;
  location_lng?: number;
  location_name?: string;
  watering_frequency_days?: number;
  sunlight?: string;
  difficulty?: string;
  notes?: string;
  last_watering?: string;
}

interface WeatherData {
  current: {
    temp: number;
    humidity: number;
    weather: { main: string; description: string; icon: string }[];
    rain?: { '1h': number };
  };
  hourly: {
    dt: number;
    temp: number;
    humidity: number;
    pop: number; // Probability of precipitation
    rain?: { '1h': number };
    weather: { main: string; description: string }[];
  }[];
  daily: {
    dt: number;
    summary: string;
    temp: { min: number; max: number };
    humidity: number;
    pop: number;
    rain?: number;
    weather: { main: string; description: string }[];
  }[];
}

interface WateringRecommendation {
  timeframe: '24h' | '72h';
  should_water: boolean;
  urgency: 'none' | 'low' | 'medium' | 'high' | 'critical';
  recommended_date?: string;
  confidence: 'low' | 'medium' | 'high';
  reasoning: string;
  water_amount_ml?: number;
  factors: {
    temperature_avg: number;
    humidity_avg: number;
    rain_probability: number;
    expected_rain_mm: number;
    days_since_last_watering: number | null;
    plant_needs: string;
  };
  weather_alerts: string[];
}

interface WateringResponse {
  success: boolean;
  plant: {
    id: string;
    name: string;
    species: string;
    location?: string;
  };
  recommendations: {
    next_24h: WateringRecommendation;
    next_72h: WateringRecommendation;
  };
  current_weather: {
    temp: number;
    humidity: number;
    condition: string;
    icon_url: string;
  };
  forecast_summary: string;
  error?: string;
  timestamp: string;
  processing_time_ms: number;
}

// ============================================================================
// CONFIGURACIÓN
// ============================================================================

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENWEATHER_API_KEY = Deno.env.get("OPENWEATHER_API_KEY")!;

// Umbrales para decisiones de riego
const THRESHOLDS = {
  HIGH_TEMP: 30,           // °C - A partir de aquí aumenta necesidad de agua
  LOW_HUMIDITY: 40,      // % - Por debajo aumenta necesidad
  HIGH_HUMIDITY: 70,     // % - Por encima reduce necesidad
  RAIN_PROB_LOW: 0.3,    // 30% - Umbral de lluvia significativa
  RAIN_PROB_HIGH: 0.7,   // 70% - Lluvia muy probable
  RAIN_AMOUNT_SIGNIFICANT: 5, // mm - Cantidad que reduce riego
};

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  const startTime = Date.now();

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
    // 1. VALIDACIÓN JWT
    // ========================================================================
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return createErrorResponse(401, "Se requiere token de autenticación", headers, startTime);
    }

    const jwt = authHeader.replace("Bearer ", "");
    const supabaseClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
      global: { headers: { Authorization: `Bearer ${jwt}` } },
    });

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return createErrorResponse(401, "Token inválido o expirado", headers, startTime);
    }

    // ========================================================================
    // 2. VALIDACIÓN DE PARÁMETROS
    // ========================================================================
    let requestBody: WateringRequest;
    try {
      requestBody = await req.json();
    } catch {
      return createErrorResponse(400, "Body inválido (JSON malformado)", headers, startTime);
    }

    const { plant_id } = requestBody;
    if (!plant_id) {
      return createErrorResponse(400, "Se requiere 'plant_id'", headers, startTime);
    }

    console.log(`🌱 Generando recomendación para planta: ${plant_id}, usuario: ${user.id}`);

    // ========================================================================
    // 3. OBTENER DATOS DE LA PLANTA
    // ========================================================================
    const plant = await getPlantData(supabaseClient, plant_id, user.id);
    if (!plant) {
      return createErrorResponse(404, "Planta no encontrada o no pertenece al usuario", headers, startTime);
    }

    // Verificar que tiene ubicación
    if (!plant.location_lat || !plant.location_lng) {
      return createErrorResponse(400, "La planta no tiene ubicación configurada", headers, startTime);
    }

    // ========================================================================
    // 4. CONSULTAR CLIMA (OpenWeather One Call API 3.0)
    // ========================================================================
    const weather = await fetchWeatherData(plant.location_lat, plant.location_lng);
    if (!weather) {
      return createErrorResponse(503, "Error al obtener datos meteorológicos", headers, startTime);
    }

    // ========================================================================
    // 5. CALCULAR RECOMENDACIONES
    // ========================================================================
    const recommendation24h = calculateRecommendation(plant, weather, 24);
    const recommendation72h = calculateRecommendation(plant, weather, 72);

    // ========================================================================
    // 6. CONSTRUIR RESPUESTA
    // ========================================================================
    const response: WateringResponse = {
      success: true,
      plant: {
        id: plant.id,
        name: plant.name,
        species: plant.species,
        location: plant.location_name,
      },
      recommendations: {
        next_24h: recommendation24h,
        next_72h: recommendation72h,
      },
      current_weather: {
        temp: Math.round(weather.current.temp),
        humidity: weather.current.humidity,
        condition: weather.current.weather[0].description,
        icon_url: `https://openweathermap.org/img/wn/${weather.current.weather[0].icon}@2x.png`,
      },
      forecast_summary: generateForecastSummary(weather, recommendation24h, recommendation72h),
      timestamp: new Date().toISOString(),
      processing_time_ms: Date.now() - startTime,
    };

    console.log(`✅ Recomendación generada en ${response.processing_time_ms}ms`);
    console.log(`   24h: ${recommendation24h.should_water ? 'REGAR' : 'NO REGAR'} (${recommendation24h.urgency})`);
    console.log(`   72h: ${recommendation72h.should_water ? 'REGAR' : 'NO REGAR'} (${recommendation72h.urgency})`);

    return new Response(JSON.stringify(response), { status: 200, headers });

  } catch (error) {
    console.error("❌ Error no controlado:", error);
    return createErrorResponse(500, "Error interno del servidor", headers, startTime);
  }
});

// ============================================================================
// SERVICIO: OBTENER DATOS DE PLANTA
// ============================================================================

async function getPlantData(
  supabase: any,
  plantId: string,
  userId: string
): Promise<PlantData | null> {
  // Consultar planta con último riego (si existe)
  const { data: plant, error } = await supabase
    .from("plants")
    .select(`
      *,
      watering_logs:watering_logs(date, amount_ml)
    `)
    .eq("id", plantId)
    .eq("user_id", userId)
    .order("date", { foreignTable: "watering_logs", ascending: false })
    .limit(1, { foreignTable: "watering_logs" })
    .single();

  if (error || !plant) {
    console.error("Error obteniendo planta:", error);
    return null;
  }

  // Extraer último riego
  const lastWatering = plant.watering_logs?.[0]?.date;

  return {
    id: plant.id,
    name: plant.name,
    species: plant.species || "Desconocida",
    location_lat: plant.location_lat,
    location_lng: plant.location_lng,
    location_name: plant.location_name,
    watering_frequency_days: plant.watering_frequency_days,
    sunlight: plant.sunlight,
    difficulty: plant.difficulty,
    notes: plant.notes,
    last_watering: lastWatering,
  };
}

// ============================================================================
// SERVICIO: OPENWEATHER ONE CALL API
// ============================================================================

async function fetchWeatherData(lat: number, lon: number): Promise<WeatherData | null> {
  if (!OPENWEATHER_API_KEY) {
    console.error("❌ OPENWEATHER_API_KEY no configurada");
    return null;
  }

  try {
    console.log(`🌤️ Consultando clima para: ${lat}, ${lon}`);

    // One Call API 3.0 - Incluye current, hourly (48h), daily (8 días)
    const url = `https://api.openweathermap.org/data/3.0/onecall?` +
      `lat=${lat}&lon=${lon}` +
      `&exclude=minutely,alerts` +
      `&units=metric` +
      `&lang=es` +
      `&appid=${OPENWEATHER_API_KEY}`;

    const response = await fetch(url, { method: "GET" });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`OpenWeather error ${response.status}:`, errorText);
      return null;
    }

    const data = await response.json();
    console.log(`✅ Datos climáticos obtenidos: ${data.current.temp}°C, ${data.current.humidity}% humedad`);

    return data as WeatherData;

  } catch (error) {
    console.error("❌ Error fetching weather:", error);
    return null;
  }
}

// ============================================================================
// LÓGICA DE RECOMENDACIÓN
// ============================================================================

function calculateRecommendation(
  plant: PlantData,
  weather: WeatherData,
  hours: 24 | 72
): WateringRecommendation {
  const now = Date.now() / 1000;
  const cutoffTime = now + (hours * 3600);

  // Filtrar datos horarios relevantes
  const relevantHours = weather.hourly.filter(h => h.dt <= cutoffTime);

  // Calcular promedios
  const avgTemp = relevantHours.reduce((sum, h) => sum + h.temp, 0) / relevantHours.length;
  const avgHumidity = relevantHours.reduce((sum, h) => sum + h.humidity, 0) / relevantHours.length;

  // Probabilidad máxima de lluvia
  const maxRainProb = Math.max(...relevantHours.map(h => h.pop || 0));

  // Lluvia esperada acumulada
  const expectedRain = relevantHours.reduce((sum, h) => {
    return sum + ((h.rain?.['1h'] || 0) * (h.pop || 0));
  }, 0);

  // Días desde último riego
  const daysSinceWatering = plant.last_watering
    ? Math.floor((Date.now() - new Date(plant.last_watering).getTime()) / (1000 * 3600 * 24))
    : null;

  // Determinar necesidad base de la especie
  const plantNeeds = getPlantWaterNeeds(plant);

  // ========================================================================
  // LÓGICA DE DECISIÓN
  // ========================================================================

  let shouldWater = false;
  let urgency: WateringRecommendation['urgency'] = 'none';
  let reasoning = "";
  let waterAmountMl: number | undefined;
  const weatherAlerts: string[] = [];

  // Factores que aumentan necesidad de riego
  let needScore = 0;
  let needReasons: string[] = [];
  let avoidReasons: string[] = [];

  // 1. Basado en frecuencia recomendada
  if (plant.watering_frequency_days && daysSinceWatering !== null) {
    if (daysSinceWatering >= plant.watering_frequency_days) {
      needScore += 3;
      needReasons.push(`Han pasado ${daysSinceWatering} días desde el último riego (recomendado: cada ${plant.watering_frequency_days} días)`);
    } else if (daysSinceWatering >= plant.watering_frequency_days * 0.8) {
      needScore += 1;
      needReasons.push(`Próximo riego recomendado en breve`);
    }
  }

  // 2. Temperatura alta
  if (avgTemp > THRESHOLDS.HIGH_TEMP) {
    needScore += 2;
    needReasons.push(`Temperatura alta prevista (${avgTemp.toFixed(1)}°C)`);
  }

  // 3. Humedad baja
  if (avgHumidity < THRESHOLDS.LOW_HUMIDITY) {
    needScore += 2;
    needReasons.push(`Humedad ambiental baja (${avgHumidity.toFixed(0)}%)`);
  }

  // 4. Humedad alta (reduce necesidad)
  if (avgHumidity > THRESHOLDS.HIGH_HUMIDITY) {
    needScore -= 1;
    avoidReasons.push(`Humedad ambiental alta (${avgHumidity.toFixed(0)}%)`);
  }

  // 5. Lluvia esperada (reduce necesidad significativamente)
  if (maxRainProb > THRESHOLDS.RAIN_PROB_HIGH && expectedRain > THRESHOLDS.RAIN_AMOUNT_SIGNIFICANT) {
    needScore -= 4;
    avoidReasons.push(`Lluvia muy probable (${(maxRainProb * 100).toFixed(0)}%) con ${expectedRain.toFixed(1)}mm esperados`);
    weatherAlerts.push(`🌧️ Se espera lluvia significativa - posible aplazamiento de riego`);
  } else if (maxRainProb > THRESHOLDS.RAIN_PROB_LOW && expectedRain > 2) {
    needScore -= 2;
    avoidReasons.push(`Posible lluvia (${(maxRainProb * 100).toFixed(0)}%)`);
    weatherAlerts.push(`🌦️ Lluvia ligera posible - considerar reducir cantidad`);
  }

  // 6. Necesidades específicas de la especie
  if (plantNeeds === 'high') {
    needScore += 1;
    needReasons.push(`${plant.species} requiere riego frecuente`);
  } else if (plantNeeds === 'low') {
    needScore -= 1;
    avoidReasons.push(`${plant.species} es resistente a sequía`);
  }

  // Determinar decisión final
  if (needScore >= 3) {
    shouldWater = true;
    urgency = needScore >= 5 ? 'critical' : needScore >= 4 ? 'high' : 'medium';
    reasoning = `REGAR: ${needReasons.join('. ')}`;
    waterAmountMl = calculateWaterAmount(plant, avgTemp, avgHumidity, expectedRain);
  } else if (needScore >= 1) {
    shouldWater = true;
    urgency = 'low';
    reasoning = `REGAR CON PRECAUCIÓN: ${needReasons.join('. ')}. ${avoidReasons.length > 0 ? 'PERO: ' + avoidReasons.join('. ') : ''}`;
    waterAmountMl = calculateWaterAmount(plant, avgTemp, avgHumidity, expectedRain) * 0.7;
  } else {
    shouldWater = false;
    urgency = 'none';
    reasoning = `NO REGAR: ${avoidReasons.join('. ')}${needReasons.length > 0 ? '. Aunque: ' + needReasons.join('. ') : ''}`;
  }

  // Fecha recomendada si debe regar
  let recommendedDate: string | undefined;
  if (shouldWater) {
    // Si hay lluvia inminente en las próximas 6h, posponer
    const rainSoon = relevantHours
      .slice(0, 6)
      .some(h => (h.pop || 0) > THRESHOLDS.RAIN_PROB_HIGH);

    if (rainSoon && hours === 24) {
      recommendedDate = new Date(Date.now() + 12 * 3600 * 1000).toISOString();
      weatherAlerts.push(`⏰ Posponiendo recomendación 12h por lluvia inminente`);
    } else {
      recommendedDate = new Date().toISOString();
    }
  }

  return {
    timeframe: hours === 24 ? '24h' : '72h',
    should_water: shouldWater,
    urgency,
    recommended_date: recommendedDate,
    confidence: expectedRain > 10 ? 'low' : maxRainProb > 0.5 ? 'medium' : 'high',
    reasoning,
    water_amount_ml: waterAmountMl ? Math.round(waterAmountMl) : undefined,
    factors: {
      temperature_avg: Math.round(avgTemp * 10) / 10,
      humidity_avg: Math.round(avgHumidity),
      rain_probability: Math.round(maxRainProb * 100),
      expected_rain_mm: Math.round(expectedRain * 10) / 10,
      days_since_last_watering: daysSinceWatering,
      plant_needs: plantNeeds,
    },
    weather_alerts: weatherAlerts,
  };
}

// ============================================================================
// UTILIDADES
// ============================================================================

function getPlantWaterNeeds(plant: PlantData): 'low' | 'medium' | 'high' {
  const lowWaterPlants = ['cactus', 'suculenta', 'crasa', 'aloe', 'agave', 'echeveria', 'sedum'];
  const highWaterPlants = ['helecho', 'calathea', 'monstera', 'filodendro', 'potus', 'ficus'];

  const species = plant.species.toLowerCase();

  if (lowWaterPlants.some(p => species.includes(p))) return 'low';
  if (highWaterPlants.some(p => species.includes(p))) return 'high';
  return 'medium';
}

function calculateWaterAmount(
  plant: PlantData,
  avgTemp: number,
  avgHumidity: number,
  expectedRain: number
): number {
  // Cantidad base según especie
  let baseAmount = 200; // ml por defecto

  const needs = getPlantWaterNeeds(plant);
  if (needs === 'low') baseAmount = 100;
  if (needs === 'high') baseAmount = 400;

  // Ajustes por clima
  if (avgTemp > 30) baseAmount *= 1.3;
  if (avgTemp > 35) baseAmount *= 1.5;
  if (avgHumidity < 30) baseAmount *= 1.2;
  if (avgHumidity > 70) baseAmount *= 0.8;

  // Reducir por lluvia esperada
  if (expectedRain > 5) baseAmount *= 0.5;
  if (expectedRain > 10) baseAmount *= 0.3;

  return Math.max(50, Math.min(1000, baseAmount)); // Entre 50ml y 1000ml
}

function generateForecastSummary(
  weather: WeatherData,
  rec24h: WateringRecommendation,
  rec72h: WateringRecommendation
): string {
  const next24h = weather.hourly.slice(0, 24);
  const maxTemp = Math.max(...next24h.map(h => h.temp));
  const minTemp = Math.min(...next24h.map(h => h.temp));
  const maxRain = Math.max(...next24h.map(h => h.pop || 0));

  let summary = `Próximas 24h: ${minTemp.toFixed(0)}°C - ${maxTemp.toFixed(0)}°C`;

  if (maxRain > 0.5) {
    summary += `, lluvia probable`;
  } else {
    summary += `, sin lluvia esperada`;
  }

  if (rec24h.should_water && rec72h.should_water) {
    summary += `. Riego recomendado en ambos períodos.`;
  } else if (rec24h.should_water) {
    summary += `. Riego recomendado en 24h, luego evaluar.`;
  } else if (rec72h.should_water) {
    summary += `. Sin riego urgente, revisar en 72h.`;
  } else {
    summary += `. No se requiere riego en los próximos días.`;
  }

  return summary;
}

function createErrorResponse(
  status: number,
  message: string,
  headers: Record<string, string>,
  startTime: number
): Response {
  return new Response(
    JSON.stringify({
      success: false,
      error: message,
      timestamp: new Date().toISOString(),
      processing_time_ms: Date.now() - startTime,
    }),
    { status, headers }
  );
}
