import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/navigation/main_scaffold.dart';
import 'package:planticula/features/auth/presentation/screens/login_screen.dart';
import 'package:planticula/features/auth/presentation/screens/register_screen.dart';
import 'package:planticula/features/plants/presentation/screens/plants_screen.dart';
import 'package:planticula/features/plants/presentation/screens/plant_detail_screen.dart';
import 'package:planticula/features/pest_alerts/presentation/screens/pest_alerts_list_screen.dart';
import 'package:planticula/features/pest_alerts/presentation/screens/report_pest_screen.dart';

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
        // Main routes with shell
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(
              path: AppConstants.routePlants,
              builder: (context, state) => const PlantsScreen(),
            ),
            GoRoute(
              path: AppConstants.routePlantDetail,
              builder: (context, state) => PlantDetailScreen(
                plantId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        // Pest Alerts routes
        ShellRoute(
          navigatorKey: GlobalKey<NavigatorState>(),
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(
              path: AppConstants.routePestAlerts,
              builder: (context, state) => const PestAlertsListScreen(),
            ),
          ],
        ),
        GoRoute(
          path: AppConstants.routeReportPest,
          builder: (context, state) => const ReportPestScreen(),
        ),
      ],
    );
  }
}
