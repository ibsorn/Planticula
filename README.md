# Planticula

A Flutter + Supabase plant-care app, evolving from a B2C personal-plant manager
into a B2B agricultural IoT platform with organizations, sites, gardens, and
automation devices.

## Features

### Plant management (core)
- **Plant CRUD**: create plants manually or via AI-assisted identification.
- **Watering reminders**: weather-aware watering frequency calculator
  (temperature, rain forecast, humidity, species traits, pot size, growth stage).
- **Transplant tracking**: per-species schedules with "urgent / upcoming / none"
  status based on pot size and time since last transplant.
- **Custom names & species catalog**: 200+ species with strains/varieties,
  scientific names, and care metadata.
- **Grid & list views**, search, and quick filters (indoor / outdoor / thirsty).

### Gardens as a contextual filter
- **Garden → Group → Plant** hierarchy (introduced in migration 012).
- Gardens are **not a separate tab**: they appear as a contextual filter bar
  (`GardenFilterBar`) on the Plants screen — the same pattern used by Apple
  Photos albums or Todoist projects.
- "Todas" shows every plant; selecting a garden filters instantly; selecting a
  group narrows further. The bar is hidden when no gardens exist (zero noise).
- Full garden management (create / edit / delete / groups) is reachable from
  the bar's ⚙ button via the `/gardens` management screen.
- The `PlantEditorScreen` lets you assign a plant to a garden and group at
  creation or edit time.

### AI tools
All AI features run through an `IdentificationPipeline` with a primary
**EdgeFunctionProvider** (production — API keys kept as Supabase secrets) and a
fallback **LlmVisionProvider** (development — keys in `.env`).

- **Plant identification**: photo → species, family, care notes, toxicity.
- **Seed identification**: photo → seed species and germination tips.
- **Plant disease diagnosis**: photo → disease, severity, treatment.
- **Soil analysis**: photo → pH, moisture, soil type, and amendments.

### Community
- **Pest alerts**: geo-located pest reports with photo, severity, and
  confirmation count; nearby alerts sorted by distance.
- **Marketplace**: local listings for plants, cuttings, substrate, and tools.
  Listing types: sale, trade, giveaway. Geo-located with status
  (active / reserved / sold).

### Other
- **Care guides**: searchable in-app guides per species.
- **Profile & theme**: light / dark / system theme, auth session management.
- **i18n**: Spanish (es-ES) and English (en-US) locales.

## Screens & navigation

Bottom navigation (4 tabs):

| Tab | Route | Screen |
|---|---|---|
| 0 — Plants | `/plants` | Plants list with `GardenFilterBar` |
| 1 — Tools | `/tools` | AI tools hub |
| 2 — Community | `/pest-alerts` | Pest alerts list |
| 3 — Profile | `/profile` | Profile & settings |

Full-screen routes (no bottom nav): plant editor, plant detail, garden
management (`/gardens`), garden editor, garden detail, pest report, pest
detail, marketplace listing detail / create, soil analysis & detail, plant
disease & result, plant identification & result, seed identification & result.

Routing uses `go_router` with a `ShellRoute` for the bottom nav. Static
segments are always declared before dynamic ones
(e.g. `/plants/editor` before `/plants/:id`).

## Tech stack

| Layer | Technology | Notes |
|---|---|---|
| Frontend | Flutter 3.x, Dart 3 | Clean Architecture, feature-first |
| State | `flutter_bloc` | No Riverpod/Provider/setState for business logic |
| Navigation | `go_router` | `ShellRoute` for bottom nav |
| DI | `get_it` (`sl` alias) | Manual registration in `injection.dart` |
| Network | `Result<T>` (`Success`/`Failure`) | Repositories never throw |
| Backend | Supabase | PostgreSQL + Edge Functions + Storage, RLS on every table |
| AI | OpenRouter LLM + PlantNet API | Via `IdentificationPipeline` |

### Key dependencies
`supabase_flutter`, `flutter_bloc`, `go_router`, `get_it`, `dartz`,
`equatable`, `flutter_dotenv`, `cached_network_image`, `image_picker`,
`shared_preferences`, `flutter_form_builder`, `flutter_svg`, `shimmer`,
`geolocator`, `flutter_local_notifications`, `intl`, `logger`, `http`,
`confetti`.

## Project structure

```
lib/
├── core/
│   ├── ai/              # IdentificationPipeline, Edge/LLM providers
│   ├── constants/       # AppConstants (routes), AppStrings
│   ├── data/            # Species catalog (local_species_catalog, plant_species)
│   ├── di/              # injection.dart (GetIt)
│   ├── navigation/      # app_router.dart, main_scaffold.dart
│   ├── network/         # Result<T>, AppSupabaseClient
│   ├── providers/       # Theme, etc.
│   ├── services/        # AI services, weather, location, species, watering
│   ├── theme/           # AppColors, AppDimens, AppTheme, ThemeCubit
│   └── utils/           # Logger, helpers
├── features/
│   ├── auth/            # Supabase Auth (email/password)
│   ├── gardens/         # Garden + GardenGroup hierarchy
│   ├── guides/          # Care guides
│   ├── marketplace/     # Local plant marketplace
│   ├── pest_alerts/     # Geo-located pest reports
│   ├── plant_disease/   # AI disease diagnosis
│   ├── plant_identification/ # Standalone plant ID (Tools)
│   ├── plants/          # Core plant domain
│   ├── profile/         # User profile & settings
│   ├── seed_identification/ # AI seed ID
│   ├── soil_analysis/   # AI soil analysis
│   ├── today/           # Today's tasks (in progress)
│   └── tools/           # AI tools hub
└── shared/
    └── widgets/         # EmptyState, StatusRing, CarouselSelector, AppBottomSheet…
```

Each feature follows strict Clean Architecture:

```
feature_name/
├── data/
│   ├── datasources/     # abstract class + impl (Supabase)
│   ├── models/          # extend domain entities, fromJson/toJson
│   └── repositories/    # implement domain contract
├── domain/
│   ├── entities/        # Equatable, no Flutter imports
│   └── repositories/    # abstract class (contract)
└── presentation/
    ├── bloc/            # *_bloc.dart + part files for event/state
    ├── screens/
    └── widgets/
```

## Data model

Current hierarchy (implemented through migration 012):

```
User
  └── Garden           ← "My balcony", "Greenhouse A"
        └── GardenGroup ← "Tomatoes", "Succulents"
              └── Plant ← species, watering, photos
```

`garden_id` and `group_id` on `plants` are **nullable** (`ON DELETE SET NULL`)
so existing plants remain unclassified until the user organizes them. A
`get_or_create_default_garden()` RPC guarantees every user has at least one
garden ("Mi Jardín") on first use.

### Roadmap hierarchy (B2B)

```
Organization (future)
  └── Site (future)
        └── Garden
              └── GardenGroup
                    └── Plant
                          └── SensorReading / ActuatorCommand (future IoT)
```

## Database

- **Naming**: `snake_case` plural tables (`plants`, `gardens`, `garden_groups`).
- **FKs**: always `<table>_id` (`garden_id`, `user_id`).
- **Timestamps**: `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at` via
  the `update_updated_at_column()` trigger.
- **RLS** enabled on every table with per-operation policies
  (`auth.uid() = user_id`).
- **Migrations** live in `supabase/migrations/` (001–012).
- **`MASTER_SETUP.sql`** is the idempotent master script — kept in sync with
  the incremental migrations. When adding a table, update both.

### Supabase Edge Functions

Located in `supabase/functions/`:

| Function | Purpose |
|---|---|
| `identify-plant` | Plant species identification |
| `identify-seed` | Seed identification |
| `diagnose-disease` | Plant disease diagnosis |
| `analyze-soil` / `analyze-soil-photo` | Soil analysis |
| `generate-care-info` | Care metadata generation |
| `watering-recommendation` | Weather-aware watering advice |
| `_shared/` | Shared utilities across functions |

## Configuration

### 1. Supabase
1. Create a project at [supabase.com](https://supabase.com).
2. Copy `.env.example` to `.env`:
   ```bash
   copy .env.example .env
   ```
3. Fill in your credentials:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
4. Run the migrations in `supabase/migrations/` in order (or execute
   `MASTER_SETUP.sql` for a fresh setup).

### 2. AI providers (optional in development)
- **Production**: set Edge Function secrets via
  `supabase secrets set OPENROUTER_API_KEY=...` — no client keys needed.
- **Development fallback**: uncomment `OPENROUTER_*` keys in `.env` to call
  the LLM directly from the app when Edge Functions aren't deployed.
- Per-feature overrides (`PLANT_ID_*`, `SOIL_AI_*`, `DISEASE_AI_*`,
  `SEED_ID_*`) are supported for development with separate providers.

### 3. Install & run
```bash
flutter pub get
flutter run
```

## Verification commands

```bash
# Static analysis (must report 0 errors)
flutter analyze --no-pub

# Debug build
flutter build apk --debug --no-pub

# Unit tests
flutter test test/unit/
```

## Architecture conventions

- **Blocs** hold all business logic; screens stay declarative.
- **State** uses separate `status` (list load) and `opStatus` (CRUD operation)
  enums to avoid state collisions.
- **Global blocs** (`AuthBloc`, `PlantsBloc`, `GardenBloc`, `SoilAnalysisBloc`,
  `PestAlertsBloc`, `MarketplaceBloc`, `PlantDiseaseBloc`,
  `PlantIdentificationBloc`, `SeedIdentificationBloc`) are provided once at the
  root in `main.dart`. Access them with `context.read<T>()` — never create
  additional instances in the router or screens.
- **Datasources** inject `user_id` via `_client.currentUser?.id`; repositories
  stay user-agnostic.
- **No exceptions** escape repositories — wrap errors in `Failure(message)`.
- **`.withValues(alpha: x)`** instead of the deprecated `withOpacity`.
- **Static route segments** must be declared before dynamic ones
  (`/gardens/editor` before `/gardens/:id`).
- **`MASTER_SETUP.sql`** and the incremental migration must always be updated
  together.

## License

MIT
