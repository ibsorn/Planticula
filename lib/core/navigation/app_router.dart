import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/navigation/main_scaffold.dart';
import 'package:planticula/features/auth/presentation/screens/login_screen.dart';
import 'package:planticula/features/auth/presentation/screens/register_screen.dart';
import 'package:planticula/features/plants/presentation/screens/plants_screen.dart';
import 'package:planticula/features/plants/presentation/screens/plant_detail_screen.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
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

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router({
    required bool isAuthenticated,
  }) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppConstants.routeLogin,
      redirect: (context, state) {
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
              path: '/soil-analysis',
              builder: (context, state) => const SoilAnalysisScreen(),
            ),
            // Guides
            GoRoute(
              path: '/guides',
              builder: (context, state) => const GuidesScreen(),
            ),
            // Profile
            GoRoute(
              path: AppConstants.routeProfile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        // Full-screen routes (no bottom nav)
        GoRoute(
          path: AppConstants.routeReportPest,
          builder: (context, state) => const ReportPestScreen(),
        ),
        GoRoute(
          path: AppConstants.routeCreateListing,
          builder: (context, state) => const CreateListingScreen(),
        ),
        GoRoute(
          path: '/soil-analysis/:id',
          builder: (context, state) {
            final analysis = state.extra as SoilAnalysis;
            return AnalysisDetailScreen(analysis: analysis);
          },
        ),
        GoRoute(
          path: '/listing/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ListingDetailScreen(listingId: id);
          },
        ),
      ],
    );
  }
}
