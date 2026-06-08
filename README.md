# Planticula

App de cultivo de plantas con Flutter + Supabase. MVP con autenticación, gestión de plantas y arquitectura preparada para escalar.

## Funcionalidades

- **Autenticación**: Login y registro con email/password (Supabase Auth)
- **Mis Plantas**: CRUD de plantas del usuario
- **Tema**: Claro/oscuro automático o manual
- **Navegación**: Bottom Navigation con GoRouter
- **Arquitectura**: Feature-first, Clean Architecture

## Estructura del Proyecto

```
lib/
├── core/
│   ├── constants/       # Constantes de la app
│   ├── di/             # Dependency Injection
│   ├── navigation/     # Router y navegación
│   ├── network/        # Supabase client, Result wrapper
│   ├── theme/          # Tema claro/oscuro
│   └── utils/          # Utilidades generales
├── features/
│   ├── auth/           # Feature: Autenticación
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── plants/         # Feature: Mis Plantas
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/             # Widgets y utilidades compartidas
    ├── widgets/
    └── extensions/
```

## Dependencias Principales

```yaml
# Supabase
supabase_flutter: ^2.3.4

# State Management
flutter_bloc: ^8.1.3

# Navigation
go_router: ^13.0.1

# Dependency Injection
get_it: ^7.6.4

# Otros
dartz: ^0.10.1
equatable: ^2.0.5
flutter_dotenv: ^5.1.0
shared_preferences: ^2.2.2
```

## Configuración

### 1. Configurar Supabase

1. Crea un proyecto en [Supabase](https://supabase.com)
2. Copia el archivo `.env.example` a `.env`:
   ```bash
   copy .env.example .env
   ```
3. Edita `.env` con tus credenciales:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

### 2. Configurar Tablas en Supabase

Ejecuta este SQL en el SQL Editor de Supabase:

```sql
-- Tabla de plantas
CREATE TABLE plants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    scientific_name TEXT,
    species_id UUID,
    image_url TEXT,
    acquired_date DATE,
    location TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Políticas RLS (Row Level Security)
ALTER TABLE plants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own plants" ON plants
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own plants" ON plants
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own plants" ON plants
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own plants" ON plants
    FOR DELETE USING (auth.uid() = user_id);
```

### 3. Instalar Dependencias

```bash
flutter pub get
```

## Ejecutar la App

```bash
# Desarrollo
flutter run

# Android release
flutter build apk --release

# Android app bundle
flutter build appbundle
```

## Edge Functions

Para funcionalidades futuras (análisis de imágenes, clima, plagas), prepara Edge Functions en `supabase/functions/`:

```typescript
// supabase/functions/analyze-soil/index.ts
// supabase/functions/weather-recommendations/index.ts
// supabase/functions/pest-alerts/index.ts
```

## Próximos Pasos

1. [ ] Añadir pantalla de crear/editar planta
2. [ ] Implementar galería de fotos por planta
3. [ ] Integrar análisis de sustrato (Edge Function + ML)
4. [ ] Guías por especie (base de datos + búsqueda)
5. [ ] Recomendaciones de riego según clima
6. [ ] Marketplace local
7. [ ] Alertas de plagas por zona

## Arquitectura

- **Feature-first**: Cada feature tiene sus capas data/domain/presentation
- **Clean Architecture**: Separación clara de responsabilidades
- **BLoC Pattern**: State management predecible
- **Dependency Injection**: GetIt para inyección de dependencias
- **No secrets en cliente**: Toda lógica sensible en Edge Functions

## Licencia

MIT
