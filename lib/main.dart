import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/di/injection.dart' as di;
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/navigation/app_router.dart';
import 'package:planticula/core/theme/app_theme.dart';
import 'package:planticula/core/theme/theme_cubit.dart';
import 'package:planticula/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/features/soil_analysis/presentation/bloc/soil_analysis_bloc.dart';
import 'package:planticula/features/pest_alerts/presentation/bloc/pest_alerts_bloc.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:planticula/features/plant_disease/presentation/bloc/plant_disease_bloc.dart';
import 'package:planticula/features/plant_identification/presentation/bloc/plant_identification_bloc.dart';
import 'package:planticula/features/seed_identification/presentation/bloc/seed_identification_bloc.dart';

export 'core/navigation/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies (SharedPreferences, etc.)
  await di.initDependencies();

  // Initialize Supabase - continue even if it fails (will show error screen)
  bool supabaseInitialized = false;
  String? supabaseError;

  try {
    await AppSupabaseClient.instance.initialize();
    supabaseInitialized = true;
  } on SupabaseConfigException catch (e) {
    supabaseError = e.message;
    debugPrint('⚠️ Supabase configuration error: $e');
  } catch (e) {
    supabaseError = 'Error initializing Supabase: ${e.toString()}';
    debugPrint('❌ Supabase initialization failed: $e');
  }

  runApp(MyApp(
    supabaseInitialized: supabaseInitialized,
    supabaseError: supabaseError,
  ));
}

class MyApp extends StatelessWidget {
  final bool supabaseInitialized;
  final String? supabaseError;

  const MyApp({
    super.key,
    required this.supabaseInitialized,
    this.supabaseError,
  });

  @override
  Widget build(BuildContext context) {
    // Show error screen if Supabase failed to initialize
    if (!supabaseInitialized && supabaseError != null) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error de Configuración',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    supabaseError!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Para configurar:\n'
                    '1. Copia .env.example a .env\n'
                    '2. Añade tus credenciales de Supabase',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => di.sl<ThemeCubit>(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(),
        ),
        BlocProvider<PlantsBloc>(
          create: (context) => di.sl<PlantsBloc>(),
        ),
        BlocProvider<SoilAnalysisBloc>(
          create: (context) => di.sl<SoilAnalysisBloc>(),
        ),
        BlocProvider<PestAlertsBloc>(
          create: (context) => di.sl<PestAlertsBloc>(),
        ),
        BlocProvider<MarketplaceBloc>(
          create: (context) => di.sl<MarketplaceBloc>(),
        ),
        BlocProvider<PlantDiseaseBloc>(
          create: (context) => di.sl<PlantDiseaseBloc>(),
        ),
        BlocProvider<PlantIdentificationBloc>(
          create: (context) => di.sl<PlantIdentificationBloc>(),
        ),
        BlocProvider<SeedIdentificationBloc>(
          create: (context) => di.sl<SeedIdentificationBloc>(),
        ),
      ],
      child: _AppContent(),
    );
  }
}

/// Separated widget that listens to auth changes and updates the router's
/// AuthNotifier without recreating the GoRouter instance.
class _AppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.isAuthenticated != current.isAuthenticated,
      listener: (context, state) {
        // Update the router's auth notifier - this triggers GoRouter's
        // refreshListenable which re-evaluates redirects without
        // destroying the navigation stack.
        AppRouter.authNotifier.isAuthenticated = state.isAuthenticated;
      },
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            routerConfig: AppRouter.router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', 'ES'),
              Locale('en', 'US'),
            ],
          );
        },
      ),
    );
  }
}
