# Guía de Configuración Supabase para Planticula

Este documento describe paso a paso cómo configurar tu proyecto de Supabase para funcionar con la app Planticula.

## 1. Crear Proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com) e inicia sesión
2. Clic en "New Project"
3. Elige tu organización
4. Configura:
   - **Name**: `planticula` (o el nombre que prefieras)
   - **Database Password**: Genera una segura y guárdala
   - **Region**: Elige la más cercana a tus usuarios (ej: `West US` para LATAM)
   - **Pricing Plan**: Free tier
5. Clic en "Create new project"
6. Espera ~2 minutos a que se provisione

## 2. Obtener Credenciales

Una vez creado el proyecto:

1. Ve a **Project Settings** (icono de engranaje) → **API**
2. Copia estos valores:
   - **Project URL** (ej: `https://xxxxxxxxxxxxxxxxxxxx.supabase.co`)
   - **anon/public** key (empieza con `eyJ...`)

3. En tu proyecto Flutter, copia el archivo `.env.example` a `.env`:
   ```bash
   copy .env.example .env
   ```

4. Edita `.env` con tus credenciales:
   ```
   SUPABASE_URL=https://xxxxxxxxxxxxxxxxxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

   ⚠️ **IMPORTANTE**: Nunca subas el archivo `.env` a git. Está incluido en `.gitignore`.

## 3. Configurar Autenticación (Auth)

### 3.1 Habilitar Email/Password

1. Ve a **Authentication** → **Providers**
2. Asegúrate de que **Email** está habilitado
3. Configuración recomendada:
   - ✅ **Enable Email confirmations**: OFF (para desarrollo)
   - ✅ **Secure email change**: ON
   - ✅ **Enable Signup**: ON

### 3.2 Configurar Site URL (para redirecciones)

1. Ve a **Authentication** → **URL Configuration**
2. En **Site URL**, añade:
   - Para desarrollo: `http://localhost:3000`
   - Para producción: `https://tu-dominio.com`
3. En **Redirect URLs**, añade:
   - `io.supabase.planticula://login-callback/`

## 4. Crear Tablas en Database

Ve al **SQL Editor** (pestaña SQL en el menú lateral) y ejecuta los siguientes scripts:

### 4.1 Tabla de Plantas

Usa el archivo de migración ubicado en `supabase/migrations/001_initial_schema.sql` o copia este SQL:

```sql
-- Tabla de plantas del usuario
CREATE TABLE plants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL CHECK (char_length(name) > 0),
    scientific_name TEXT,
    species_id UUID,
    image_url TEXT,
    acquired_date DATE,
    location TEXT,
    notes TEXT,
    watering_frequency INTEGER CHECK (watering_frequency > 0), -- Días entre riegos
    last_watered TIMESTAMP WITH TIME ZONE,
    next_watering TIMESTAMP WITH TIME ZONE, -- Calculado automáticamente
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Índices para búsquedas frecuentes
CREATE INDEX idx_plants_user_id ON plants(user_id);
CREATE INDEX idx_plants_name ON plants(name);
CREATE INDEX idx_plants_next_watering ON plants(next_watering);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_plants_updated_at
    BEFORE UPDATE ON plants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para calcular next_watering automáticamente
CREATE OR REPLACE FUNCTION calculate_next_watering()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.watering_frequency IS NOT NULL AND NEW.last_watered IS NOT NULL THEN
        NEW.next_watering := NEW.last_watered + INTERVAL '1 day' * NEW.watering_frequency;
    ELSE
        NEW.next_watering := NULL;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER calculate_next_watering_trigger
    BEFORE INSERT OR UPDATE OF watering_frequency, last_watered ON plants
    FOR EACH ROW
    EXECUTE FUNCTION calculate_next_watering();

-- Activar Row Level Security (RLS)
ALTER TABLE plants ENABLE ROW LEVEL SECURITY;
```

### 4.2 Políticas de Seguridad (RLS)

Aún en el SQL Editor, añade estas políticas:

```sql
-- Política: Usuarios solo pueden ver sus propias plantas
CREATE POLICY "Users can view own plants" ON plants
    FOR SELECT
    USING (auth.uid() = user_id);

-- Política: Usuarios solo pueden insertar sus propias plantas
CREATE POLICY "Users can insert own plants" ON plants
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Política: Usuarios solo pueden actualizar sus propias plantas
CREATE POLICY "Users can update own plants" ON plants
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Política: Usuarios solo pueden eliminar sus propias plantas
CREATE POLICY "Users can delete own plants" ON plants
    FOR DELETE
    USING (auth.uid() = user_id);

-- Política: Permitir operaciones para usuarios autenticados (alternativa más permisiva)
-- CREATE POLICY "Enable all operations for authenticated users" ON plants
--     FOR ALL
--     USING (auth.role() = 'authenticated')
--     WITH CHECK (auth.role() = 'authenticated');
```

## 5. Configurar Storage (para imágenes)

Para subir fotos de plantas:

1. Ve a **Storage** → **New bucket**
2. Crea bucket:
   - **Name**: `plant-images`
   - ✅ **Public bucket**: SÍ (las URLs deben ser accesibles)
   - ✅ **File size limit**: 5MB
   - **Allowed MIME types**: `image/png, image/jpeg, image/jpg`
3. Clic en **Create bucket**

### 5.1 Políticas de Storage

Ve a **Storage** → **plant-images** → **Policies** → **New policy**

Crea estas políticas:

#### SELECT (descargar imágenes)
```sql
-- Permitir que cualquiera vea las imágenes públicas
CREATE POLICY "Allow public access to plant images" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'plant-images');
```

#### INSERT (subir imágenes)
```sql
-- Solo usuarios autenticados pueden subir
CREATE POLICY "Allow authenticated users to upload" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'plant-images' AND
        auth.role() = 'authenticated' AND
        (storage.extension(name) = 'jpg' OR
         storage.extension(name) = 'jpeg' OR
         storage.extension(name) = 'png')
    );
```

#### DELETE (eliminar imágenes)
```sql
-- Solo el propietario puede eliminar
CREATE POLICY "Allow owners to delete their images" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'plant-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );
```

## 6. Edge Functions (Preparación Futura)

Para funcionalidades futuras (análisis de sustrato, clima, plagas), crea las funciones Edge:

### 6.1 Instalar CLI de Supabase

```bash
npm install -g supabase
```

### 6.2 Inicializar en tu proyecto

```bash
supabase init
```

### 6.3 Crear función de ejemplo

```bash
supabase functions new analyze-soil
```

Esto creará `supabase/functions/analyze-soil/index.ts`.

### 6.4 Ejemplo: Análisis de Sustrato

```typescript
// supabase/functions/analyze-soil/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const { image_url } = await req.json();

  // Aquí integrarías con una API de ML/IA
  // Por ejemplo: OpenAI Vision API, Google Vision, etc.

  const analysis = {
    soil_type: "Loamy",
    ph_level: 6.5,
    moisture: "Adequate",
    recommendations: [
      "Añadir compost para mejorar drenaje",
      "pH óptimo para la mayoría de plantas"
    ]
  };

  return new Response(
    JSON.stringify(analysis),
    { headers: { "Content-Type": "application/json" } },
  );
});
```

### 6.5 Desplegar función

```bash
supabase functions deploy analyze-soil
```

## 7. Verificar Configuración

Para verificar que todo está correcto, ejecuta estas consultas en el SQL Editor:

```sql
-- Verificar que RLS está activado en plants
SELECT relname, relrowsecurity
FROM pg_class
WHERE relname = 'plants';

-- Debe retornar: plants | true

-- Verificar políticas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'plants';

-- Debe mostrar 4 políticas (SELECT, INSERT, UPDATE, DELETE)
```

## 8. Testing

### 8.1 Crear usuario de prueba vía SQL (opcional)

```sql
-- Crear usuario directamente (solo para desarrollo)
-- Nota: Esto es solo para pruebas, en producción usa la API de Auth
```

### 8.2 Verificar con API REST

Supabase genera automáticamente una API REST. Prueba con curl:

```bash
# Obtener token de autenticación primero
curl -X POST 'https://tu-proyecto.supabase.co/auth/v1/token?grant_type=password' \
  -H "apikey: TU_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "password123"}'

# Luego usa el token para consultar plantas
curl -X GET 'https://tu-proyecto.supabase.co/rest/v1/plants' \
  -H "apikey: TU_ANON_KEY" \
  -H "Authorization: Bearer TOKEN_AQUI"
```

## 9. Configuración para Producción

Antes de lanzar a producción:

### 9.1 Habilitar Confirmaciones de Email

1. Ve a **Authentication** → **Providers** → **Email**
2. Activa **Enable Email confirmations**
3. Configura plantillas de email en **Authentication** → **Email Templates**

### 9.2 Configurar OAuth (Opcional)

Para login con Google, Apple, etc.:

1. **Authentication** → **Providers**
2. Habilita los proveedores deseados
3. Configura las credenciales de cada proveedor

### 9.3 Backups Automáticos

En **Database** → **Backups**, configura:
- Daily backups (incluido en free tier)
- Point-in-time recovery (pro tier)

## 10. Troubleshooting

### Error: "Invalid API key"
- Verifica que `SUPABASE_ANON_KEY` es correcto
- No uses la `service_role` key en el cliente

### Error: "new row violates row-level security policy"
- Verifica que las políticas RLS están creadas
- Asegúrate de que el usuario está autenticado

### Error: "JWT expired"
- El token de sesión expiró
- La app debería refrescar automáticamente con `auth.refreshSession()`

### Error: "Bucket not found"
- Verifica que el bucket `plant-images` existe
- Verifica que las políticas de storage están creadas

## Recursos Adicionales

- [Supabase Flutter Docs](https://supabase.com/docs/reference/dart/)
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [RLS Policies Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Storage Guide](https://supabase.com/docs/guides/storage)

## Resumen de Configuración

| Componente | Estado | Notas |
|------------|--------|-------|
| Auth Email/Password | ✅ Requerido | Habilitar en Providers |
| Tabla `plants` | ✅ Requerido | Con RLS y triggers |
| Storage `plant-images` | ✅ Opcional | Para fotos de plantas |
| Edge Functions | 🔄 Futuro | Análisis de sustrato, clima |

---

**Nota de Seguridad**: Nunca expongas la `service_role` key en el código del cliente. Solo usa `anon` key en la app Flutter. Usa Edge Functions para operaciones que requieran privilegios elevados.
