# Edge Function: analyze-soil

Analiza imágenes de sustrato/suelo y devuelve características detectadas.

## Despliegue

```bash
# Instalar Supabase CLI (si no lo tienes)
npm install -g supabase

# Login
supabase login

# Link a tu proyecto
supabase link --project-ref YOUR_PROJECT_REF

# Desplegar la función
supabase functions deploy analyze-soil
```

## Uso

### Desde Flutter

```dart
final response = await supabase.functions.invoke(
  'analyze-soil',
  body: {'analysis_id': 'uuid-del-analisis'},
);
```

### Curl

```bash
curl -X POST "https://your-project.functions.supabase.co/analyze-soil" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"analysis_id": "uuid-del-analisis"}'
```

## Respuesta

```json
{
  "success": true,
  "analysis_id": "uuid",
  "result": {
    "soil_type": "loamy",
    "ph_level": 6.5,
    "moisture_level": "optimal",
    "drainage_quality": "good",
    "organic_matter": "moderate",
    "recommendations": [
      "Añadir materia orgánica...",
      "Riego cada 5-7 días..."
    ],
    "notes": "Análisis completado"
  }
}
```

## Integración con IA Real

Actualmente la función usa análisis simulado. Para implementar análisis real:

### Opción 1: OpenAI GPT-4 Vision

```typescript
// En performSoilAnalysis()
const base64Image = await blobToBase64(imageData);

const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    model: "gpt-4-vision-preview",
    messages: [
      {
        role: "system",
        content: "Eres un experto en agricultura y jardinería. Analiza el sustrato de la imagen."
      },
      {
        role: "user",
        content: [
          { type: "text", text: "Analiza este sustrato/suelo y devuelve: tipo de sustrato, pH estimado, nivel de humedad, calidad de drenaje, nivel de materia orgánica, y 3 recomendaciones específicas. Responde en JSON." },
          { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64Image}` } }
        ]
      }
    ],
    max_tokens: 1000,
  }),
});

const result = await openaiResponse.json();
// Parsear resultado y devolver
```

### Opción 2: Google Cloud Vision

```typescript
const visionResponse = await fetch(
  `https://vision.googleapis.com/v1/images:annotate?key=${Deno.env.get("GOOGLE_VISION_API_KEY")}`,
  {
    method: "POST",
    body: JSON.stringify({
      requests: [{
        image: { content: base64Image },
        features: [
          { type: "LABEL_DETECTION", maxResults: 10 },
          { type: "IMAGE_PROPERTIES", maxResults: 5 },
        ],
      }],
    }),
  }
);
```

## Variables de Entorno Necesarias

```bash
# Supabase (automáticas)
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY

# Para IA real (agregar en Dashboard → Settings → Edge Functions)
OPENAI_API_KEY=sk-...
# o
GOOGLE_VISION_API_KEY=...
```

## Configuración en Supabase Dashboard

1. Ve a **Edge Functions**
2. Selecciona `analyze-soil`
3. En **Secrets**, agrega tu API key de OpenAI o Google Vision
4. La función usará la clave automáticamente vía `Deno.env.get()`
