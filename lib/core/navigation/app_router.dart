import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/services/plant_identification_service.dart';
import 'package:planticula/core/navigation/main_scaffold.dart';
import 'package:planticula/features/auth/presentation/screens/login_screen.dart';
import 'package:planticula/features/auth/presentation/screens/register_screen.dart';
import 'package:planticula/features/plants/presentation/screens/plant_editor_screen.dart';
import 'package:planticula/features/plants/presentation/screens/plant_identification_screen.dart';
import 'package:planticula/features/plants/presentation/screens/plants_screen.dart';
import 'package:planticula/features/plants/presentation/screens/plant_detail_screen.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';

import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/presentation/screens/pest_alert_detail_screen.dart';
import 'package:planticula/features/pest_alerts/presentation/screens/pest_alerts_list_screen.dart';
import 'package:planticula/features/pest_alerts/presentation/screens/report_pest_screen.dart';
import 'package:planticula/features/marketplace/presentation/screens/marketplace_list_screen.dart';
import 'package:planticula/features/marketplace/presentation/screens/create_listing_screen.dart';
import 'package:planticula/features/marketplace/presentation/screens/listing_detail_screen.dart';
import 'package:planticula/features/soil_analysis/presentation/screens/soil_analysis_screen.dart';
import 'package:planticula/features/soil_analysis/presentation/screens/analysis_detail_screen.dart';
import 'package:planticula/features/soil_analysis/domain/entities/soil_analysis.dart';
import 'package:planticula/features/profile/presentation/screens/profile_screen.dart';
import 'package:planticula/features/guides/presentation/screens/guides_screen.dart';
import 'package:planticula/features/tools/presentation/screens/tools_screen.dart';
import 'package:planticula/features/plant_disease/presentation/screens/plant_disease_screen.dart';
import 'package:planticula/features/plant_disease/presentation/screens/diagnosis_result_screen.dart';
import 'package:planticula/features/plant_disease/domain/entities/plant_disease_diagnosis.dart';
import 'package:planticula/features/plant_identification/presentation/screens/plant_identification_screen.dart';
import 'package:planticula/features/plant_identification/presentation/screens/plant_identification_result_screen.dart';
import 'package:planticula/features/plant_identification/domain/entities/plant_identification_result.dart';
import 'package:planticula/features/seed_identification/presentation/screens/seed_identification_screen.dart';
import 'package:planticula/features/seed_identification/presentation/screens/seed_identification_result_screen.dart';
import 'package:planticula/features/seed_identification/domain/entities/seed_identification_result.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart' as garden_entity;
import 'package:planticula/features/gardens/presentation/screens/gardens_screen.dart';
import 'package:planticula/features/gardens/presentation/screens/garden_detail_screen.dart';
import 'package:planticula/features/gardens/presentation/screens/garden_editor_screen.dart';

/// Notifier that GoRouter listens to for auth state changes.
/// When auth changes, the router re-evaluates its redirect logic
/// WITHOUT recreating the entire router instance.
class AuthNotifier extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  set isAuthenticated(bool value) {
    if (_isAuthenticated != value) {
      _isAuthenticated = value;
      notifyListeners();
    }
  }
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final AuthNotifier authNotifier = AuthNotifier();

  static final GoRouter _router = _createRouter();

  static GoRouter get router => _router;

  static GoRouter _createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppConstants.routePlants,
      refreshListenable: authNotifier,
      redirect: (context, state) {
        final isAuthenticated = authNotifier.isAuthenticated;
        final isAuthRoute = state.matchedLocation == AppConstants.routeLogin ||
            state.matchedLocation == AppConstants.routeRegister;

        if (!isAuthenticated && !isAuthRoute) {
          return AppConstants.routeLogin;
        }

        if (isAuthenticated && isAuthRoute) {
          return AppConstants.routePlants;
        }

        return null;
      },
      routes: [
        // Auth routes
        GoRoute(
          path: AppConstants.routeLogin,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppConstants.routeRegister,
          builder: (context, state) => const RegisterScreen(),
        ),
        // Main routes with shell (bottom nav)
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            // Plants
            GoRoute(
              path: AppConstants.routePlants,
              builder: (context, state) => const PlantsScreen(),
            ),
            // Plant identification (camera/AI)
            GoRoute(
              path: AppConstants.routePlantIdentification,
              builder: (context, state) => const PlantIdentificationScreen(),
            ),
            // IMPORTANT: Editor route must come BEFORE detail route
            // to avoid /plants/editor being captured by /plants/:id
            GoRoute(
              path: AppConstants.routePlantEditor,
              builder: (context, state) {
                final args = state.extra as Map<String, dynamic>?;
                if (args == null) {
                  return const PlantEditorScreen.manual();
                }
                final mode = args['mode'] as PlantEditorMode;
                switch (mode) {
                  case PlantEditorMode.manual:
                    return const PlantEditorScreen.manual();
                  case PlantEditorMode.aiAssisted:
                    return PlantEditorScreen.aiAssisted(
                      identificationResult: args['identificationResult'] as PlantIdentificationResult,
                      imageBytes: args['imageBytes'] as Uint8List,
                    );
                  case PlantEditorMode.edit:
                    return PlantEditorScreen.edit(
                      existingPlant: args['existingPlant'] as Plant,
                    );
                }
              },
            ),
            GoRoute(
              path: AppConstants.routePlantDetail,
              builder: (context, state) {
                final plant = state.extra as Plant?;
                if (plant != null) {
                  return PlantDetailScreen(plant: plant);
                }
                return PlantDetailScreen(
                  plant: Plant(
                    id: state.pathParameters['id']!,
                    name: 'Cargando...',
                  ),
                );
              },
            ),
            // Tools hub (soil analysis + guides)
            GoRoute(
              path: AppConstants.routeTools,
              builder: (context, state) => const ToolsScreen(),
            ),
            // Pest Alerts
            GoRoute(
              path: AppConstants.routePestAlerts,
              builder: (context, state) => const PestAlertsListScreen(),
            ),
            // Marketplace
            GoRoute(
              path: AppConstants.routeMarketplace,
              builder: (context, state) => const MarketplaceListScreen(),
            ),
            // Soil Analysis
            GoRoute(
              path: AppConstants.routeSoilAnalysis,
              builder: (context, state) => const SoilAnalysisScreen(),
            ),
            // Guides
            GoRoute(
              path: AppConstants.routeGuides,
              builder: (context, state) => const GuidesScreen(),
            ),
            // Plant Disease Diagnosis
            GoRoute(
              path: AppConstants.routePlantDisease,
              builder: (context, state) => const PlantDiseaseScreen(),
            ),
            // Plant Identification V2
            GoRoute(
              path: AppConstants.routePlantIdentificationV2,
              builder: (context, state) => const PlantIdentificationV2Screen(),
            ),
            // Seed Identification
            GoRoute(
              path: AppConstants.routeSeedIdentification,
              builder: (context, state) => const SeedIdentificationScreen(),
            ),
            // Jardines (shell — con bottom nav)
            // GardenBloc ya está provisto en main.dart
            GoRoute(
              path: AppConstants.routeGardens,
              builder: (context, state) => const GardensScreen(),
            ),
            // Profile
            GoRoute(
              path: AppConstants.routeProfile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        // Full-screen routes (no bottom nav)
        // IMPORTANT: routeReportPest ('/pest-alerts/report') must be declared
        // BEFORE routePestAlertDetail ('/pest-alerts/:id') so GoRouter matches
        // the static 'report' segment before the parameterised ':id' wildcard.
        GoRoute(
          path: AppConstants.routeReportPest,
          builder: (context, state) => const ReportPestScreen(),
        ),
        GoRoute(
          path: AppConstants.routePestAlertDetail,
          builder: (context, state) {
            final alert = state.extra as PestAlert;
            return PestAlertDetailScreen(alert: alert);
          },
        ),
        GoRoute(
          path: AppConstants.routePlantDiagnosisResult,
          builder: (context, state) {
            final diagnosis = state.extra as PlantDiseaseDiagnosis;
            return DiagnosisResultScreen(diagnosis: diagnosis);
          },
        ),
        GoRoute(
          path: AppConstants.routeCreateListing,
          builder: (context, state) => const CreateListingScreen(),
        ),
        GoRoute(
          path: AppConstants.routeSoilAnalysisDetail,
          builder: (context, state) {
            final analysis = state.extra as SoilAnalysis;
            return AnalysisDetailScreen(analysis: analysis);
          },
        ),
        GoRoute(
          path: AppConstants.routePlantIdentificationResult,
          builder: (context, state) {
            final record = state.extra as PlantIdentificationRecord;
            return PlantIdentificationResultScreen(record: record);
          },
        ),
        GoRoute(
          path: AppConstants.routeSeedIdentificationResult,
          builder: (context, state) {
            final record = state.extra as SeedIdentificationRecord;
            return SeedIdentificationResultScreen(record: record);
          },
        ),
        GoRoute(
          path: AppConstants.routeListingDetail,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ListingDetailScreen(listingId: id);
          },
        ),
        // ── Gardens ──────────────────────────────────────────────────────
        // IMPORTANT: routeGardenEditor ('/gardens/editor') must be declared
        // BEFORE routeGardenDetail ('/gardens/:id') so the static segment wins.
        // GardenBloc y PlantsBloc ya están provisto en main.dart
        GoRoute(
          path: AppConstants.routeGardenEditor,
          builder: (context, state) {
            final garden = state.extra as garden_entity.Garden?;
            return GardenEditorScreen(garden: garden);
          },
        ),
        GoRoute(
          path: AppConstants.routeGardenDetail,
          builder: (context, state) {
            final garden = state.extra as garden_entity.Garden;
            return GardenDetailScreen(garden: garden);
          },
        ),
      ],
    );
  }
}
