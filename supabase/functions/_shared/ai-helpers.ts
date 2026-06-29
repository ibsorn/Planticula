// ============================================================================
// SHARED AI HELPERS — Used by all Edge Functions
// ============================================================================
// Provides: CORS, LLM vision calls, LLM text calls, PlantNet API calls,
//           JSON extraction, image optimization hints.
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Allowed origins for CORS — restrict to your app's domains.
// In production, replace "*" with your actual domain(s).
const ALLOWED_ORIGINS = Deno.env.get("ALLOWED_ORIGINS")?.split(",") ?? ["*"];

export function getCorsHeaders(origin?: string | null): Record<string, string> {
  let allowedOrigin = ALLOWED_ORIGINS[0];
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    allowedOrigin = origin;
  } else if (ALLOWED_ORIGINS.includes("*")) {
    allowedOrigin = "*";
  }
  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers":
      "apikey, Authorization, Content-Type, x-client-info",
  };
}

// Backwards-compatible constant (defaults to wildcard when ALLOWED_ORIGINS
// is not set, which keeps dev environments working out of the box).
export const corsHeaders = getCorsHeaders();

export function handleCors(req: Request): Response | null {
  const origin = req.headers.get("Origin");
  const headers = getCorsHeaders(origin);
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers });
  }
  return null;
}

export function jsonResponse(
  data: Record<string, unknown>,
  status = 200,
  origin?: string | null,
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...getCorsHeaders(origin), "Content-Type": "application/json" },
  });
}

export function errorResponse(
  message: string,
  status = 500,
  origin?: string | null,
): Response {
  return jsonResponse({ error: message }, status, origin);
}

// ============================================================================
// JWT AUTHENTICATION HELPER
// ============================================================================

/**
 * Validates the Authorization header and returns the authenticated user.
 * Returns an error Response if authentication fails, or the user object.
 */
export async function requireAuth(
  req: Request,
): Promise<{ user: { id: string } } | Response> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return errorResponse(
      "Authentication required",
      401,
      req.headers.get("Origin"),
    );
  }

  const jwt = authHeader.replace("Bearer ", "");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return errorResponse("Server configuration error", 500, req.headers.get("Origin"));
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });

  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return errorResponse(
      "Invalid or expired token",
      401,
      req.headers.get("Origin"),
    );
  }

  return { user: { id: user.id } };
}

// ============================================================================
// ENVIRONMENT CONFIG
// ============================================================================

export function getEnv(key: string): string {
  const val = Deno.env.get(key);
  if (!val) throw new Error(`Missing env var: ${key}`);
  return val;
}

export function getEnvOrDefault(key: string, fallback: string): string {
  return Deno.env.get(key) ?? fallback;
}

// ============================================================================
// LLM VISION CALL (OpenAI-compatible / OpenRouter)
// ============================================================================

interface LlmVisionOptions {
  prompt: string;
  base64Image: string;
  maxTokens?: number;
  temperature?: number;
}

export async function callLlmVision(
  opts: LlmVisionOptions,
): Promise<string> {
  const apiKey = getEnv("OPENROUTER_API_KEY");
  const baseUrl = getEnvOrDefault(
    "OPENROUTER_BASE_URL",
    "https://openrouter.ai/api/v1",
  );
  const model = getEnvOrDefault(
    "OPENROUTER_MODEL",
    "qwen/qwen3-vl-8b-instruct",
  );

  const response = await fetch(`${baseUrl}/chat/completions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://planticula.app",
      "X-Title": "Planticula Edge Function",
    },
    body: JSON.stringify({
      model,
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: opts.prompt },
            {
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${opts.base64Image}`,
              },
            },
          ],
        },
      ],
      max_tokens: opts.maxTokens ?? 1000,
      temperature: opts.temperature ?? 0.2,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`LLM API error ${response.status}: ${text}`);
  }

  const json = await response.json();
  const content = json?.choices?.[0]?.message?.content as string | undefined;

  if (!content || content.length === 0) {
    throw new Error("Empty response from LLM");
  }

  return content;
}

// ============================================================================
// LLM TEXT CALL (no image — cheaper, for care info / germination info)
// ============================================================================

interface LlmTextOptions {
  prompt: string;
  maxTokens?: number;
  temperature?: number;
}

export async function callLlmText(opts: LlmTextOptions): Promise<string> {
  const apiKey = getEnv("OPENROUTER_API_KEY");
  const baseUrl = getEnvOrDefault(
    "OPENROUTER_BASE_URL",
    "https://openrouter.ai/api/v1",
  );
  const model = getEnvOrDefault(
    "OPENROUTER_TEXT_MODEL",
    getEnvOrDefault("OPENROUTER_MODEL", "qwen/qwen3-vl-8b-instruct"),
  );

  const response = await fetch(`${baseUrl}/chat/completions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://planticula.app",
      "X-Title": "Planticula Edge Function",
    },
    body: JSON.stringify({
      model,
      messages: [
        { role: "user", content: opts.prompt },
      ],
      max_tokens: opts.maxTokens ?? 800,
      temperature: opts.temperature ?? 0.3,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`LLM text API error ${response.status}: ${text}`);
  }

  const json = await response.json();
  const content = json?.choices?.[0]?.message?.content as string | undefined;

  if (!content || content.length === 0) {
    throw new Error("Empty response from LLM text");
  }

  return content;
}

// ============================================================================
// PLANTNET API CALL
// ============================================================================

export interface PlantNetResult {
  scientificName: string;
  commonName: string | null;
  family: string | null;
  score: number; // 0..1
  gbifId: number | null;
}

export async function callPlantNet(
  base64Image: string,
): Promise<PlantNetResult | null> {
  const apiKey = Deno.env.get("PLANTNET_API_KEY");
  if (!apiKey) {
    console.log("[PlantNet] No API key configured, skipping");
    return null;
  }

  // Convert base64 to binary
  const binary = base64ToUint8Array(base64Image);

  // Build multipart form data
  const formData = new FormData();
  formData.append("organs", "auto");
  formData.append(
    "images",
    new Blob([binary], { type: "image/jpeg" }),
    "image.jpg",
  );

  const url =
    `https://my-api.plantnet.org/v2/identify/all?api-key=${apiKey}` +
    `&nb-results=5&lang=es&include-related-images=false`;

  const response = await fetch(url, {
    method: "POST",
    body: formData,
  });

  if (!response.ok) {
    const text = await response.text();
    console.error(`[PlantNet] API error ${response.status}: ${text}`);
    return null;
  }

  const data = await response.json();
  const results = data?.results;

  if (!Array.isArray(results) || results.length === 0) {
    return null;
  }

  const best = results[0];
  const score = best.score ?? 0;
  const species = best.species;

  return {
    scientificName: species?.scientificName ?? "Desconocido",
    commonName: species?.commonNames?.[0] ?? null,
    family: species?.family?.scientificName ?? null,
    score,
    gbifId: species?.gbifId ?? null,
  };
}

// ============================================================================
// JSON EXTRACTION
// ============================================================================

export function extractJson(text: string): string {
  // Try markdown code block first
  const codeBlockRegex = /```(?:json)?\s*([\s\S]*?)```/;
  const match = codeBlockRegex.exec(text);
  if (match) return match[1].trim();

  // Fall back to raw JSON
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start >= 0 && end > start) return text.substring(start, end + 1);

  return text.trim();
}

export function parseJsonResponse(text: string): Record<string, unknown> {
  const jsonStr = extractJson(text);
  return JSON.parse(jsonStr) as Record<string, unknown>;
}

// ============================================================================
// UTILITIES
// ============================================================================

function base64ToUint8Array(base64: string): Uint8Array {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

export function numOrNull(val: unknown): number | null {
  if (typeof val === "number") return val;
  if (typeof val === "string" && !isNaN(Number(val))) return Number(val);
  return null;
}

export function boolOrNull(val: unknown): boolean | null {
  if (typeof val === "boolean") return val;
  if (typeof val === "string") {
    if (val === "true") return true;
    if (val === "false") return false;
  }
  return null;
}

export function stringListOrNull(val: unknown): string[] | null {
  if (Array.isArray(val)) {
    return val.map((e) => String(e));
  }
  return null;
}
