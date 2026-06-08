# Edge Function: analyze-soil-photo

Analiza fotos de sustrato/suelo usando IA visual (OpenAI GPT-4 Vision) y devuelve métricas de humedad, compactación, drenaje y recomendaciones.

## Características

- **Validación JWT**: Verifica autenticación del usuario
- **Análisis IA**: Integración con OpenAI Vision para análisis visual real
- **Respuesta estructurada**: JSON tipado con humedad, compactación, drenaje y recomendaciones
- **Fallback**: Modo simulado si no hay API key configurada
- **CORS habilitado**: Listo para ser llamado desde Flutter app

## Estructura Modular

```
analyze-soil-photo/
├── index.ts              # Handler principal con validación
├── Servicio IA           # analyzeWithOpenAI() - Llamada a proveedor externo
├── Respuesta             # Estructura JSON tipada
└── Fallback              # generateSimulatedAnalysis() - Demo sin IA
```

## Respuesta JSON

```json
{
  "success": true,
  "data": {
    "humidity": {
      "level": "medium",
      "estimated_percentage": 50,
      "description": "Sustrato con humedad equilibrada"
    },
    "compaction": {
      "level": "low",
      "description": "Sustrato suelto con buena aireación"
    },
    "drainage": {
      "probability": "high",
      "estimated_score": 80,
      "description": "Alto drenaje probable por textura"
    },
    "recommendation": "Mantener riego actual, el sustrato está en buenas condiciones",
    "raw_analysis": "..." // Opcional, para debugging
  },
  "timestamp": "2024-01-15T10:30:00.000Z",
  "processing_time_ms": 2450
}
```

## Despliegue con Supabase CLI

### Prerrequisitos

```bash
# 1. Instalar Supabase CLI
npm install -g supabase

# 2. Login a Supabase
supabase login

# 3. Link a tu proyecto (una sola vez)
supabase link --project-ref YOUR_PROJECT_REF
```

### Paso 1: Configurar Variables de Entorno

```bash
# Crear archivo .env.local (no versionar)
echo "OPENAI_API_KEY=sk-..." > .env.local

# O configurar en Supabase Dashboard:
# Dashboard → Settings → Edge Functions → Secrets
```

Variables necesarias:
- `OPENAI_API_KEY` (opcional - sin esto usa modo simulado)

### Paso 2: Desplegar la Función

```bash
# Desplegar desde directorio raíz del proyecto
supabase functions deploy analyze-soil-photo

# Verificar despliegue
supabase functions list
```

### Paso 3: Configurar Secrets en Producción

```bash
# Set secret desde CLI
supabase secrets set OPENAI_API_KEY=sk-...

# Verificar secrets
supabase secrets list
```

### Paso 4: Probar la Función

```bash
# Test local (después de supabase start)
curl -X POST "http://localhost:54321/functions/v1/analyze-soil-photo" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "image_url": "https://ejemplo.com/suelo.jpg"
  }'

# Test producción
curl -X POST "https://YOUR_PROJECT.functions.supabase.co/analyze-soil-photo" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "image_path": "user-id/timestamp_soil.jpg"
  }'
```

## Uso desde Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Usar image_url (URL pública completa)
final response = await supabase.functions.invoke(
  'analyze-soil-photo',
  body: {
    'image_url': 'https://tu-proyecto.supabase.co/storage/v1/object/public/soil-images/user-id/12345_soil.jpg',
    'plant_id': 'uuid-opcional',
  },
);

// O usar image_path (path relativo al bucket)
final response2 = await supabase.functions.invoke(
  'analyze-soil-photo',
  body: {
    'image_path': 'user-id/12345_soil.jpg',
    'plant_id': 'uuid-opcional',
  },
);

final data = response.data;

if (data['success']) {
  final result = data['data'];
  print('Humedad: ${result['humidity']['description']}');
  print('Compactación: ${result['compaction']['level']}');
  print('Drenaje: ${result['drainage']['probability']}');
  print('Recomendación: ${result['recommendation']}');
}
```

## Integración con App Planticula

### Guardar Resultado en BD

```dart
// Después de obtener análisis, guardar en tabla soil_analyses
final analysisResult = await supabase.functions.invoke(
  'analyze-soil-photo',
  body: {'image_url': imageUrl},
);

if (analysisResult.data['success']) {
  final result = analysisResult.data['data'];

  // Mapear a tu schema
  await supabase.from('soil_analyses').insert({
    'user_id': userId,
    'plant_id': plantId, // opcional
    'image_url': imageUrl,
    'status': 'completed',
    'soil_type': _inferSoilType(result),
    'ph_level': null, // La IA no detecta pH visualmente
    'moisture_level': result['humidity']['level'],
    'drainage_quality': result['drainage']['probability'],
    'analysis_notes': result['recommendation'],
    // Guardar JSON completo para referencia
    'metadata': result,
  });
}
```

## Proveedores de IA Alternativos

### Opción 1: OpenAI Vision (Implementado)
- Modelo: `gpt-4o-mini` (económico) o `gpt-4o` (más preciso)
- Costo: ~$0.005-0.015 por imagen
- Calidad: Excelente para textura y humedad

### Opción 2: Google Cloud Vision
```typescript
const response = await fetch(
  `https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}`,
  {
    method: 'POST',
    body: JSON.stringify({
      requests: [{
        image: { source: { imageUri: imageUrl } },
        features: [
          { type: 'LABEL_DETECTION', maxResults: 20 },
          { type: 'IMAGE_PROPERTIES' },
        ],
      }],
    }),
  }
);
```

### Opción 3: AWS Rekognition
```typescript
const command = new DetectLabelsCommand({
  Image: { S3Object: { Bucket: 'bucket', Name: imagePath } },
  MaxLabels: 20,
});
const response = await rekognitionClient.send(command);
```

## Costos Estimados (OpenAI)

| Modelo | Costo por 1K imágenes |
|--------|----------------------|
| gpt-4o-mini | ~$5-10 USD |
| gpt-4o | ~$25-40 USD |

Modo simulado = $0 (para desarrollo/testing)

## Troubleshooting

### "Token de autenticación inválido"
- Verificar que el header `Authorization: Bearer TOKEN` está presente
- El token debe ser válido y no expirado

### "OpenAI API error"
- Verificar que `OPENAI_API_KEY` está configurado en Secrets
- Verificar que la API key tiene saldo disponible
- Revisar límites de rate limit

### Timeout (5s+)
- OpenAI Vision puede tardar 2-5 segundos
- Considerar aumentar timeout de la Edge Function en `config.toml`

### Imagen no accesible
- Verificar que la imagen es pública o que la función tiene permisos de service_role
- Para imágenes privadas, usar `image_path` y construir URL firmada

## Actualizar Función

```bash
# Modificar código y redeploy
supabase functions deploy analyze-soil-photo

# Ver logs en tiempo real
supabase functions logs analyze-soil-photo --tail
```

## Eliminar Función

```bash
supabase functions delete analyze-soil-photo
```
