# Edge Function: watering-recommendation

Genera recomendaciones de riego inteligentes basadas en especie de planta, ubicación geográfica y previsión meteorológica de OpenWeather.

## Características

- **JWT Validation**: Solo usuarios autenticados pueden consultar sus plantas
- **Datos en tiempo real**: Consulta OpenWeather One Call API 3.0
- **Lógica inteligente**: Ajusta recomendación según lluvia esperada, temperatura y humedad
- **Doble horizonte**: Recomendaciones para 24h y 72h
- **Respuesta enriquecida**: Incluye URL del icono meteorológico, factores considerados y alertas

## Respuesta JSON

```json
{
  "success": true,
  "plant": {
    "id": "uuid",
    "name": "Mi Monstera",
    "species": "Monstera deliciosa",
    "location": "Terraza"
  },
  "recommendations": {
    "next_24h": {
      "timeframe": "24h",
      "should_water": true,
      "urgency": "medium",
      "recommended_date": "2024-01-15T14:30:00.000Z",
      "confidence": "high",
      "reasoning": "REGAR: Han pasado 5 días desde el último riego. Temperatura alta prevista (32.5°C)",
      "water_amount_ml": 250,
      "factors": {
        "temperature_avg": 28.3,
        "humidity_avg": 45,
        "rain_probability": 10,
        "expected_rain_mm": 0,
        "days_since_last_watering": 5,
        "plant_needs": "high"
      },
      "weather_alerts": []
    },
    "next_72h": {
      "timeframe": "72h",
      "should_water": false,
      "urgency": "none",
      "confidence": "medium",
      "reasoning": "NO REGAR: Lluvia muy probable (80%) con 15.5mm esperados",
      "factors": { ... },
      "weather_alerts": ["🌧️ Se espera lluvia significativa - posible aplazamiento de riego"]
    }
  },
  "current_weather": {
    "temp": 26,
    "humidity": 60,
    "condition": "cielo claro",
    "icon_url": "https://openweathermap.org/img/wn/01d@2x.png"
  },
  "forecast_summary": "Próximas 24h: 18°C - 32°C, sin lluvia esperada. Riego recomendado en 24h, luego evaluar.",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "processing_time_ms": 850
}
```

## Lógica de Recomendación

### Factores que AUMENTAN necesidad de riego:
- Días desde último riego > frecuencia recomendada
- Temperatura > 30°C
- Humedad ambiental < 40%
- Especies de alta necesidad (helechos, monsteras)

### Factores que REDUCEN necesidad de riego:
- Probabilidad de lluvia > 30% con >2mm esperados
- Probabilidad de lluvia > 70% con >5mm esperados
- Humedad ambiental > 70%
- Especies resistentes (cactus, suculentas)

### Niveles de Urgencia:
| Urgencia | Score | Significado |
|----------|-------|-------------|
| `critical` | ≥5 | Regar urgentemente |
| `high` | 4 | Regar hoy |
| `medium` | 3 | Regar pronto |
| `low` | 1-2 | Regar si es necesario |
| `none` | ≤0 | No regar |

## Despliegue con Supabase CLI

### Prerrequisitos

```bash
# 1. Instalar Supabase CLI
npm install -g supabase

# 2. Login
supabase login

# 3. Link al proyecto
supabase link --project-ref YOUR_PROJECT_REF
```

### Configurar API Key de OpenWeather

```bash
# Obtener API key en: https://openweathermap.org/api (One Call API 3.0)
# Nota: Requiere tarjeta de crédito (tiene límites gratuitos generosos)

# Configurar secret
supabase secrets set OPENWEATHER_API_KEY=your_api_key_here

# Verificar
supabase secrets list
```

### Desplegar Función

```bash
# Desplegar
supabase functions deploy watering-recommendation

# Verificar
supabase functions list

# Ver logs en tiempo real
supabase functions logs watering-recommendation --tail
```

## Uso desde Flutter

### Request Básico

```dart
final response = await supabase.functions.invoke(
  'watering-recommendation',
  body: {'plant_id': 'uuid-de-la-planta'},
);

final data = response.data;

if (data['success']) {
  final rec24h = data['recommendations']['next_24h'];
  final rec72h = data['recommendations']['next_72h'];

  // Mostrar recomendación principal
  if (rec24h['should_water']) {
    print('💧 REGAR: ${rec24h['reasoning']}');
    print('Cantidad: ${rec24h['water_amount_ml']}ml');
    print('Urgencia: ${rec24h['urgency']}');
  } else {
    print('✅ NO REGAR: ${rec24h['reasoning']}');
  }

  // Mostrar clima actual
  final weather = data['current_weather'];
  print('🌡️ ${weather['temp']}°C, ${weather['humidity']}% humedad');
}
```

### Widget de Recomendación

```dart
class WateringRecommendationCard extends StatelessWidget {
  final Map<String, dynamic> recommendation;

  @override
  Widget build(BuildContext context) {
    final shouldWater = recommendation['should_water'] as bool;
    final urgency = recommendation['urgency'] as String;
    final amount = recommendation['water_amount_ml'] as int?;

    return Card(
      color: shouldWater ? Colors.blue.shade50 : Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  shouldWater ? Icons.water_drop : Icons.check_circle,
                  color: shouldWater ? Colors.blue : Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  shouldWater ? 'REGAR ${urgency.toUpperCase()}' : 'NO REGAR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: shouldWater ? Colors.blue : Colors.green,
                  ),
                ),
              ],
            ),
            if (amount != null) ...[
              SizedBox(height: 8),
              Text('💧 ${amount}ml recomendados'),
            ],
            SizedBox(height: 8),
            Text(recommendation['reasoning']),
            if ((recommendation['weather_alerts'] as List).isNotEmpty) ...[
              SizedBox(height: 8),
              ...recommendation['weather_alerts'].map<Widget>((alert) =>
                Text(alert, style: TextStyle(color: Colors.orange)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Testing

### Local

```bash
# Iniciar Supabase local
supabase start

# Test con curl
curl -X POST http://localhost:54321/functions/v1/watering-recommendation \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"plant_id": "test-plant-id"}'
```

### Producción

```bash
curl -X POST https://YOUR_PROJECT.functions.supabase.co/watering-recommendation \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"plant_id": "uuid-de-tu-planta"}'
```

## Requisitos de la Tabla `plants`

La función espera que la tabla `plants` tenga estos campos:

```sql
CREATE TABLE plants (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  name TEXT,
  species TEXT,
  location_lat DOUBLE PRECISION,  -- Requerido
  location_lng DOUBLE PRECISION,  -- Requerido
  location_name TEXT,
  watering_frequency_days INTEGER,
  sunlight TEXT,
  difficulty TEXT,
  notes TEXT,
  ...
);

-- Tabla opcional para historial de riegos
CREATE TABLE watering_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plant_id UUID REFERENCES plants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users,
  date TIMESTAMP WITH TIME ZONE DEFAULT now(),
  amount_ml INTEGER,
  notes TEXT
);
```

## Especies Reconocidas

### Baja necesidad de agua:
- `cactus`, `suculenta`, `crasa`, `aloe`, `agave`, `echeveria`, `sedum`

### Alta necesidad de agua:
- `helecho`, `calathea`, `monstera`, `filodendro`, `potus`, `ficus`

Las demás especies se consideran de necesidad **media**.

## Costos

### OpenWeather One Call API 3.0
- **1,000 llamadas/día**: Gratis
- Después: $0.0015 por llamada

Para una app con 1,000 usuarios activos revisando sus plantas 1 vez al día = dentro del límite gratuito.

### Supabase Edge Functions
- Incluido en tu plan actual
- Límite de ejecución: 50ms (configurable)

## Troubleshooting

### "OPENWEATHER_API_KEY no configurada"
```bash
supabase secrets set OPENWEATHER_API_KEY=sk-...
```

### "Planta no tiene ubicación configurada"
La planta debe tener `location_lat` y `location_lng` en la base de datos.

### "Error al obtener datos meteorológicos"
- Verificar que la API key es válida
- Verificar que la ubicación está dentro de rangos válidos (-90 to 90, -180 to 180)
- One Call API requiere suscripción (tarjeta requerida, pero tiene crédito gratuito)

### Timeout
La función puede tardar 1-3 segundos:
- Valida JWT (~50ms)
- Consulta BD (~100ms)
- Llama OpenWeather (~500-1500ms)
- Calcula recomendación (~50ms)

Si es muy lento, considera cachear respuestas meteorológicas.

## Mejoras Futuras Sugeridas

1. **Cache**: Guardar datos meteorológicos por ubicación por 1h para reducir llamadas a OpenWeather
2. **Historial**: Aprender de los riegos previos de cada planta para ajustar recomendaciones
3. **Sensores**: Integrar datos de sensores de humedad del sustrato si el usuario los tiene
4. **Estaciones**: Considerar estación del año en la recomendación
5. **Notificaciones**: Programar notificaciones push basadas en la recomendación

## Actualizar

```bash
# Editar código y redeploy
supabase functions deploy watering-recommendation

# Ver logs
supabase functions logs watering-recommendation --tail
```

## Eliminar

```bash
supabase functions delete watering-recommendation
```
