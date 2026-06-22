# Planticula — Guía de contexto para agentes de IA

> **Propósito de este documento**
> Evitar duplicidades, inconsistencias y decisiones arquitectónicas erróneas
> cuando un agente de IA retome el desarrollo en fases posteriores.
> Léelo ENTERO antes de tocar cualquier fichero.

---

## 1. Visión del producto

Planticula es una app Flutter (Supabase backend) que está en transición de:

- **B2C actual**: gestión individual de plantas de un usuario.
- **B2B objetivo**: plataforma agrícola IoT multiusuario con soporte para organizaciones, viveros, invernaderos y dispositivos de automatización.

La jerarquía de datos objetivo es:

```
Organization (futuro)
  └── Site (futuro)
        └── Garden  ← implementado (migración 012)
              └── GardenGroup  ← implementado (migración 012)
                    └── Plant  ← existente, conectado
                          └── SensorReading / ActuatorCommand (futuro)
```

---

## 2. Stack y convenciones inamovibles

| Capa | Tecnología | Notas |
|---|---|---|
| Frontend | Flutter 3.x, Dart 3 | Clean Architecture estricta |
| Estado | `flutter_bloc` (BLoC pattern) | **No usar Riverpod, Provider ni setState para lógica de negocio** |
| Backend | Supabase (PostgreSQL + Edge Functions) | RLS en TODAS las tablas |
| Navegación | `go_router` con ShellRoute para el bottom nav | |
| DI | `get_it` con `GetIt.instance` alias `sl` | |
| Red | Clase `Result<T>` propia (`Success`/`Failure`) — **nunca lanzar excepciones al repo** | |
| IA | OpenRouter LLM + PlantNet API vía `IdentificationPipeline` | |

---

## 3. Estructura de directorios

```
lib/
├── core/
│   ├── ai/              ← IdentificationPipeline, Edge/LLM providers
│   ├── constants/       ← AppConstants (rutas, strings)
│   ├── di/              ← injection.dart (GetIt)
│   ├── navigation/      ← app_router.dart, main_scaffold.dart
│   ├── network/         ← Result<T>, AppSupabaseClient
│   ├── services/        ← AI services (plant ID, disease, soil, seed)
│   └── theme/           ← AppColors, AppDimens, AppTheme
│
├── features/
│   ├── auth/
│   ├── gardens/         ← NUEVO (migración 012)
│   ├── marketplace/
│   ├── pest_alerts/
│   ├── plant_disease/
│   ├── plant_identification/
│   ├── plants/          ← core del dominio
│   ├── seed_identification/
│   └── soil_analysis/
│
└── shared/
    └── widgets/         ← EmptyState, StatusRing, CarouselSelector…
```

Cada feature sigue **exactamente** esta estructura interna:

```
feature_name/
├── data/
│   ├── datasources/     ← abstract class + impl (Supabase)
│   ├── models/          ← extienden las entidades de dominio
│   └── repositories/    ← implementan el contrato del dominio
├── domain/
│   ├── entities/        ← clases Equatable puras, sin imports de Flutter
│   └── repositories/    ← abstract class (contrato)
└── presentation/
    ├── bloc/            ← *_bloc.dart + *_event.dart + *_state.dart
    ├── screens/
    └── widgets/
```

---

## 4. Patrón de datos: cómo añadir una nueva entidad

Sigue SIEMPRE este orden para no romper la jerarquía de dependencias:

1. **Entidad de dominio** (`domain/entities/foo.dart`)  
   — extiende `Equatable`, campos `final`, método `copyWith`, `props`.

2. **Repositorio abstracto** (`domain/repositories/foo_repository.dart`)  
   — usa `Result<T>` para todos los retornos.

3. **Model** (`data/models/foo_model.dart`)  
   — extiende la entidad, implementa `fromJson`, `toJson`, `fromDomain`, `createJson`.

4. **Datasource abstract** (`data/datasources/foo_remote_datasource.dart`)  
   — mismos métodos que el repositorio pero devuelve `FooModel` en vez de `Foo`.

5. **Datasource impl** (`data/datasources/foo_remote_datasource_impl.dart`)  
   — recibe `AppSupabaseClient`, usa `_client.currentUser?.id` para `user_id`.  
   — **Siempre** inyecta `user_id` en el datasource, nunca en el repositorio.  
   — Captura excepciones con `try/catch` y devuelve `Failure(...)`.

6. **Repository impl** (`data/repositories/foo_repository_impl.dart`)  
   — delega al datasource, convierte si es necesario.

7. **Bloc** (`presentation/bloc/foo_bloc.dart` + event + state)  
   — usa `on<Event>(_handler)`.  
   — El estado tiene `status` (enum) + `opStatus` (enum) separados: uno para carga de lista, otro para operaciones CRUD.

8. **Registrar en `injection.dart`**:
   ```dart
   sl.registerLazySingleton<FooRemoteDataSource>(() => FooRemoteDataSourceImpl(sl()));
   sl.registerLazySingleton<FooRepository>(() => FooRepositoryImpl(sl()));
   sl.registerFactory<FooBloc>(() => FooBloc(sl()));
   ```

9. **Proveer en `main.dart`** si el bloc debe ser global (accesible desde varias rutas sin recrearse):
   ```dart
   BlocProvider<FooBloc>(create: (_) => sl<FooBloc>()),
   ```

10. **Rutas en `app_constants.dart`** y **en `app_router.dart`**.  
    — Las rutas que necesitan el bottom nav van dentro del `ShellRoute`.  
    — Las rutas full-screen (editor, detalle con parámetro) van fuera del `ShellRoute`.  
    — **IMPORTANTE**: las rutas con segmento estático (ej. `/gardens/editor`) deben declararse ANTES de las que usan parámetro dinámico (ej. `/gardens/:id`).

---

## 5. Base de datos: convenciones críticas

### Nomenclatura
- Tablas en `snake_case` plural: `gardens`, `garden_groups`, `plants`.
- FK siempre `tabla_id`: `garden_id`, `group_id`, `user_id`.
- Timestamps: `created_at TIMESTAMPTZ DEFAULT now()` y `updated_at` gestionado con el trigger `update_updated_at_column()`.

### RLS — Regla de oro
**Toda tabla nueva debe tener RLS habilitado** con políticas separadas por operación:
```sql
ALTER TABLE foo ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own foo"   ON foo FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own foo" ON foo FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own foo" ON foo FOR UPDATE USING (...) WITH CHECK (...);
CREATE POLICY "Users can delete own foo" ON foo FOR DELETE USING (auth.uid() = user_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON foo TO authenticated;
GRANT ALL ON foo TO service_role;
```

### MASTER_SETUP.sql
Es el script idempotente maestro. **Siempre** hay que mantenerlo sincronizado con las migraciones.  
Orden de secciones actual:
```
SECCIÓN 0   — DROP CASCADE (en orden inverso a dependencias)
SECCIÓN 1   — Función update_updated_at_column()
SECCIÓN 2   — species_catalog
SECCIÓN 2b  — gardens, garden_groups          ← añadido en 012
SECCIÓN 3   — plants (con garden_id, group_id) ← modificado en 012
SECCIÓN 3b  — RPCs de jardines                ← añadido en 012
SECCIÓN 4   — soil_analyses
...
```

**Al añadir una tabla nueva:**
1. Añade su `DROP TABLE IF EXISTS ... CASCADE` al principio de SECCIÓN 0 (respetando el orden de FKs).
2. Añade el `CREATE TABLE` en la sección correspondiente según sus dependencias.
3. Crea también la migración incremental `NNN_nombre.sql`.

### Columnas FK nuevas en `plants`
Las columnas `garden_id` y `group_id` son **nullable** (`ON DELETE SET NULL`).  
Nunca añadas FKs NOT NULL a `plants` sin una migration que rellene los datos existentes.

---

## 6. La feature `gardens` — mapa de ficheros

```
lib/features/gardens/
├── data/
│   ├── datasources/
│   │   ├── garden_remote_datasource.dart          ← contrato
│   │   └── garden_remote_datasource_impl.dart     ← Supabase impl
│   ├── models/
│   │   ├── garden_model.dart
│   │   └── garden_group_model.dart
│   └── repositories/
│       └── garden_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── garden.dart         ← GardenType enum, GardenIcon enum
│   │   └── garden_group.dart
│   └── repositories/
│       └── garden_repository.dart
└── presentation/
    ├── bloc/
    │   ├── garden_bloc.dart    ← part of pattern
    │   ├── garden_event.dart   ← part of 'garden_bloc.dart'
    │   └── garden_state.dart   ← part of 'garden_bloc.dart'
    ├── screens/
    │   ├── gardens_screen.dart         ← lista de jardines (tab 1)
    │   ├── garden_detail_screen.dart   ← grupos + plantas filtradas
    │   └── garden_editor_screen.dart   ← crear/editar jardín
    └── widgets/
        ├── garden_card.dart
        ├── garden_icon_mapper.dart     ← String key → IconData
        └── group_chip.dart             ← onLongPress → eliminar grupo
```

**`GardenBloc` está provisto en `main.dart` (nivel raíz)** — no crear instancias adicionales en el router ni en las screens. Acceder siempre con `context.read<GardenBloc>()`.

**El router NO hace `BlocProvider`** para las rutas de gardens — el bloc ya existe en el árbol.

---

## 7. La feature `plants` — qué se cambió en 012

| Fichero | Cambio |
|---|---|
| `domain/entities/plant.dart` | `gardenId`, `groupId` nullable + `copyWith` con `clearGardenId`/`clearGroupId` |
| `data/models/plant_model.dart` | `fromJson`, `toJson`, `fromDomain`, `copyWithModel`, `create` actualizados |
| `data/datasources/plant_remote_datasource.dart` | Añadidos: `getPlantsByGarden`, `getPlantsByGroup`, `assignPlantToGarden` |
| `data/datasources/plant_remote_datasource_impl.dart` | Implementados los 3 métodos nuevos |
| `data/repositories/plants_repository_impl.dart` | Delega los 3 métodos nuevos |
| `domain/repositories/plants_repository.dart` | Contrato ampliado con los 3 métodos nuevos |
| `presentation/bloc/plants_event.dart` | `PlantsFilterByGarden`, `PlantsFilterByGroup`, `PlantAssignToGardenRequested` |
| `presentation/bloc/plants_bloc.dart` | Handlers para los 3 nuevos eventos |

---

## 8. Navegación — bottom nav actual

```
Tab 0 — Plantas      /plants
Tab 1 — Jardines     /gardens     ← NUEVO (migración 012)
Tab 2 — Herramientas /tools
Tab 3 — Comunidad    /pest-alerts
Tab 4 — Perfil       /profile
```

Fichero: `lib/core/navigation/main_scaffold.dart`  
La lógica de selección de tab está en `_getSelectedIndex(String route)`.

---

## 9. Próximos pasos previstos (no implementados)

### Stage 2 — Asignación de plantas a jardines desde la UI existente
- `PlantEditorScreen`: añadir selector de jardín + grupo en el formulario de creación/edición.
- Al crear una planta, enviar `gardenId` y `groupId` al evento `PlantCreateRequested`.
- `PlantsRepositoryImpl.createPlant` ya acepta estos campos en `PlantModel.create`.

### Stage 3 — Organization / Site (multitenancy B2B)
- Nuevas tablas: `organizations`, `sites` con `organization_id` en `gardens`.
- RLS multiorganización: las políticas pasarán de `auth.uid() = user_id` a comprobar membresía en `organization_members`.
- Los blocs de gardens recibirán un `organizationId` de contexto.
- **NO tocar las RLS de `plants` hasta tener roles definidos** — riesgo de exposición de datos.

### Stage 4 — Dispositivos IoT
- Nuevas tablas: `sensor_types`, `actuator_types`, `devices`, `sensor_readings` (time-series).
- Los `devices` pertenecerán a un `garden_id` (ya existe la FK en gardens).
- Para telemetría considerar particionado por fecha en `sensor_readings`.
- Edge Functions para ingestión MQTT → Supabase Realtime.

### Stage 5 — Reglas de automatización
- Tabla `automation_rules` (trigger_condition, actuator_target, schedule).
- Motor de evaluación: edge-first en gateway local (Home Assistant), sincronizado con Supabase.

---

## 10. Comandos de verificación

```bash
# Análisis estático (debe dar 0 errores)
flutter analyze --no-pub

# Build de verificación
flutter build apk --debug --no-pub

# Tests unitarios
flutter test test/unit/
```

Todos deben ejecutarse desde la raíz del proyecto (`C:\...\Planticula\`).  
El binario de Flutter está en `C:\flutter\bin\flutter.bat` en esta máquina.

---

## 11. Antipatrones — qué NO hacer

| ❌ No hacer | ✅ Hacer en su lugar |
|---|---|
| Crear un segundo `GardenBloc` en el router o en una screen | `context.read<GardenBloc>()` — ya está en el árbol |
| Registrar el mismo datasource/repo dos veces en `injection.dart` | Comprobar si ya existe `sl.isRegistered<T>()` |
| Añadir `user_id` en el repositorio | Inyectarlo en el **datasource** con `_client.currentUser?.id` |
| Añadir columnas NOT NULL sin default a tablas con datos existentes | Siempre nullable o con default en la migración |
| Lanzar excepciones desde repositorios o blocs | Devolver `Failure(message)` y emitir estado de error |
| Duplicar la lógica de filtrado en la UI | Filtrar en el datasource con `.eq()` de Supabase |
| Usar `withOpacity` (deprecated en Flutter 3.27+) | Usar `.withValues(alpha: x)` |
| Poner lógica de negocio en las screens | Siempre en el Bloc |
| Crear rutas con segmento dinámico antes que el estático del mismo prefijo | Declarar `/gardens/editor` **antes** que `/gardens/:id` |
| Tocar `MASTER_SETUP.sql` sin crear también la migración incremental | Siempre los dos en paralelo |
