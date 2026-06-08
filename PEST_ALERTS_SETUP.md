# Feature: Pest Alerts (Alertas de Plagas)

Sistema de alertas geolocalizadas de plagas. Los usuarios pueden reportar plagas en sus plantas con foto y ubicación, y otros usuarios pueden ver alertas cercanas ordenadas por distancia.

## Características

- **Reportar plagas**: Foto, tipo de plaga, severidad, ubicación GPS
- **Alertas cercanas**: Listado ordenado por distancia + fecha
- **Filtros avanzados**: Radio (1-50km), días, tipos de plaga, severidad
- **Confirmaciones**: Otros usuarios pueden confirmar que vieron la misma plaga
- **Resolución**: Marcado de plagas tratadas/eliminadas

## Arquitectura

```
pest_alerts/
├── domain/
│   ├── entities/pest_alert.dart        # Entidad con PestType, Severity, AlertStatus
│   └── repositories/pest_alert_repository.dart
├── data/
│   ├── models/pest_alert_model.dart    # DTO con fromJson/toJson
│   ├── datasources/
│   │   ├── pest_alert_remote_datasource.dart
│   │   └── pest_alert_remote_datasource_impl.dart
│   └── repositories/pest_alert_repository_impl.dart
└── presentation/
    ├── bloc/pest_alerts_bloc.dart
    ├── screens/
    │   ├── pest_alerts_list_screen.dart    # Listado con filtros (2 tabs: cercanas/mis alertas)
    │   ├── report_pest_screen.dart         # Formulario de reporte
    │   └── pest_alert_detail_screen.dart   # Detalle de alerta
```

## Setup

### 1. SQL - Ejecutar en Supabase Dashboard

Abrir **SQL Editor** y ejecutar el archivo:
```
supabase/pest_alerts_schema.sql
```

Esto crea:
- Tabla `pest_alerts` con campos de ubicación
- Tabla `pest_alert_confirmations` para confirmaciones
- Función RPC `get_nearby_pest_alerts()` - consulta geográfica con Haversine
- Función RPC `get_pest_alerts_statistics()` - estadísticas del área
- Triggers para `updated_at` y contador de confirmaciones
- Políticas RLS

### 2. Storage Bucket - Crear en Dashboard

```
Storage → New bucket
├── Name: pest-photos
├── Public bucket: true
├── File size limit: 5MB
└── Allowed MIME types: image/jpeg, image/png, image/webp
```

Ejecutar después el SQL:
```
supabase/pest_alerts_storage_policies.sql
```

### 3. Dependencias (ya incluidas en pubspec.yaml)

```yaml
geolocator: ^10.1.0     # Ubicación GPS
image_picker: ^1.0.7      # Cámara/Galería
```

## Uso de la App

### Navegación

```dart
// Listado de alertas (con pestañas: cercanas / mis alertas)
context.go('/pest-alerts');

// Reportar nueva plaga
context.push('/pest-alerts/report');
```

### Reportar Plaga

```dart
context.read<PestAlertsBloc>().add(PestAlertsReportSubmitted(
  pestType: PestType.aphids,
  severity: Severity.medium,
  latitude: 40.4168,
  longitude: -3.7038,
  notes: 'Encontrado en hojas nuevas',
));
```

### Cargar Alertas Cercanas

```dart
// 1. Actualizar ubicación
context.read<PestAlertsBloc>().add(PestAlertsUpdateUserLocation(
  latitude: position.latitude,
  longitude: position.longitude,
));

// 2. Cargar alertas (se hace automáticamente)
// O manualmente:
context.read<PestAlertsBloc>().add(PestAlertsLoadNearby());
```

### Cambiar Filtros

```dart
context.read<PestAlertsBloc>().add(PestAlertsFilterChanged(
  radiusKm: 5.0,                    // Radio en km
  daysLimit: 7,                     // Últimos 7 días
  pestTypes: [PestType.aphids, PestType.spiderMites],
  severities: [Severity.high, Severity.critical],
  includeResolved: false,
));
```

### Confirmar Alerta

```dart
context.read<PestAlertsBloc>().add(PestAlertsConfirmAlert(alertId));
```

### Marcar como Resuelta

```dart
context.read<PestAlertsBloc>().add(PestAlertsMarkResolved(alertId));
```

## API SQL

### Función RPC: get_nearby_pest_alerts

```sql
SELECT * FROM public.get_nearby_pest_alerts(
    40.4168,      -- latitud usuario
    -3.7038,      -- longitud usuario
    10.0,         -- radio km
    50,           -- límite resultados
    0,            -- offset
    30,           -- días límite (opcional)
    ARRAY['aphids', 'mealybugs'],  -- tipos (opcional)
    ARRAY['high', 'critical'],     -- severidades (opcional)
    false         -- incluir resueltas
);
```

Retorna columnas de `pest_alerts` + `distance_km` calculado.

### Estadísticas

```sql
SELECT * FROM public.get_pest_alerts_statistics(40.4168, -3.7038, 10.0, 30);
```

## Modelo de Datos

### Tabla: pest_alerts

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK auth.users |
| photo_url | TEXT | URL en Storage |
| pest_type | TEXT | ENUM: aphids, spiderMites, mealybugs... |
| custom_pest_name | TEXT | Si elige "otro" |
| severity | TEXT | low/medium/high/critical |
| latitude | DECIMAL(10,8) | -90 a 90 |
| longitude | DECIMAL(11,8) | -180 a 180 |
| location_name | TEXT | Nombre descriptivo |
| notes | TEXT | Observaciones |
| status | TEXT | active/under_review/resolved... |
| confirmed_by_count | INTEGER | Confirmaciones |
| is_resolved | BOOLEAN | Plaga tratada |
| reported_at | TIMESTAMPTZ | Creación |

### Tipos de Plaga (PestType)

- `aphids` - Pulgón
- `spiderMites` - Ácaro rojo
- `mealybugs` - Cochinilla algodonosa
- `scale` - Cochinilla escama
- `whiteflies` - Mosca blanca
- `thrips` - Trips
- `fungusGnats` - Mosquito del mantillo
- `caterpillars` - Oruga
- `snails` - Caracol/babosa
- `mold` - Hongo/moho
- `rootRot` - Pudrición de raíces
- `leafMiner` - Minador de hojas
- `other` - Otra (especificar)

### Severidad (Severity)

| Nivel | Color | Significado |
|-------|-------|-------------|
| low | 🟢 Verde | Pocas plagas, planta saludable |
| medium | 🟠 Naranja | Infestación moderada |
| high | 🔴 Rojo | Infestación severa |
| critical | 🟣 Púrpura | Emergencia, riesgo de muerte |

## Seguridad

### RLS Policies

- **SELECT**: Ver alertas activas de todos + propias aunque no estén activas
- **INSERT**: Solo propias (user_id = auth.uid())
- **UPDATE/DELETE**: Solo propias
- **Confirmaciones**: No se puede confirmar propia alerta

### Storage Policies

- **Upload**: Carpeta propia (`pest-photos/{user_id}/...`)
- **Read**: Público
- **Delete**: Solo propias

## Testing

```bash
# Supabase CLI: Probar función RPC
supabase functions invoke get_nearby_pest_alerts --data '{
  "p_latitude": 40.4168,
  "p_longitude": -3.7038,
  "p_radius_km": 10
}'
```

## Troubleshooting

### "No se encontraron alertas cercanas"
- Verificar que hay alertas en la base de datos
- Aumentar radio de búsqueda
- Verificar coordenadas del usuario

### Error de permisos de ubicación
```dart
// Android: android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

// iOS: ios/Runner/Info.plist
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrar alertas cercanas</string>
```

### Función RPC no existe
Verificar que se ejecutó `pest_alerts_schema.sql` en el SQL Editor de Supabase.

## Mejoras Futuras

1. **Mapa interactivo**: Mostrar alertas en mapa (Google Maps / MapBox)
2. **Notificaciones push**: Alertar de nuevas plagas cercanas
3. **IA de identificación**: Edge Function para identificar plaga desde foto
4. **Clusters**: Agrupar múltiples alertas de la misma zona
5. **Heatmap**: Visualizar zonas con mayor incidencia de plagas
6. **Integración con clima**: Alertar si condiciones favorecen plagas reportadas
