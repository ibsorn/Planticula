import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/services/ai_provider_config.dart';
import 'package:planticula/core/services/location_service.dart';
import 'package:planticula/core/services/plant_disease_ai_service.dart';
import 'package:planticula/core/services/plant_identification_service.dart';
import 'package:planticula/core/services/plant_recommendation_service.dart';
import 'package:planticula/core/services/soil_analysis_ai_service.dart';
import 'package:planticula/core/services/species_service.dart';
import 'package:planticula/core/services/weather_service.dart';
import 'package:planticula/core/theme/theme_cubit.dart';
import 'package:planticula/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:planticula/features/auth/domain/repositories/auth_repository.dart';
import 'package:planticula/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:planticula/features/plants/data/datasources/plant_remote_datasource.dart';
import 'package:planticula/features/plants/data/datasources/plant_remote_datasource_impl.dart';
import 'package:planticula/features/plants/data/repositories/plants_repository_impl.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/features/soil_analysis/data/datasources/soil_analysis_remote_datasource.dart';
import 'package:planticula/features/soil_analysis/data/datasources/soil_analysis_remote_datasource_impl.dart';
import 'package:planticula/features/soil_analysis/data/repositories/soil_analysis_repository_impl.dart';
import 'package:planticula/features/soil_analysis/domain/repositories/soil_analysis_repository.dart';
import 'package:planticula/features/soil_analysis/presentation/bloc/soil_analysis_bloc.dart';
import 'package:planticula/features/pest_alerts/data/datasources/pest_alert_remote_datasource.dart';
import 'package:planticula/features/pest_alerts/data/datasources/pest_alert_remote_datasource_impl.dart';
import 'package:planticula/features/pest_alerts/data/repositories/pest_alert_repository_impl.dart';
import 'package:planticula/features/pest_alerts/domain/repositories/pest_alert_repository.dart';
import 'package:planticula/features/pest_alerts/presentation/bloc/pest_alerts_bloc.dart';
import 'package:planticula/features/marketplace/data/datasources/marketplace_remote_datasource.dart';
import 'package:planticula/features/marketplace/data/datasources/marketplace_remote_datasource_impl.dart';
import 'package:planticula/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:planticula/features/marketplace/domain/repositories/marketplace_repository.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:planticula/features/plant_disease/data/datasources/plant_disease_datasource.dart';
import 'package:planticula/features/plant_disease/data/datasources/plant_disease_datasource_impl.dart';
import 'package:planticula/features/plant_disease/data/repositories/plant_disease_repository_impl.dart';
import 'package:planticula/features/plant_disease/domain/repositories/plant_disease_repository.dart';
import 'package:planticula/features/plant_disease/presentation/bloc/plant_disease_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // External dependencies
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Supabase (initialized in main)
  sl.registerSingleton<AppSupabaseClient>(AppSupabaseClient.instance);

  // Core Services (singletons - share cache across the app)
  sl.registerLazySingleton<WeatherService>(() => WeatherService());
  sl.registerLazySingleton<SpeciesService>(() => SpeciesService());
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<PlantRecommendationService>(
    () => PlantRecommendationService(),
  );

  // AI provider configs — one singleton per function, resolved from .env at startup
  sl.registerLazySingleton<AiProviderConfig>(
    () => AiProviderConfig.plantIdentification(),
    instanceName: 'plantId',
  );
  sl.registerLazySingleton<AiProviderConfig>(
    () => AiProviderConfig.soilAnalysis(),
    instanceName: 'soilAi',
  );
  sl.registerLazySingleton<AiProviderConfig>(
    () => AiProviderConfig.plantDisease(),
    instanceName: 'diseaseAi',
  );

  // AI services — receive their config by constructor
  sl.registerLazySingleton<PlantIdentificationService>(
    () => PlantIdentificationService(
      sl<SpeciesService>(),
      sl<AiProviderConfig>(instanceName: 'plantId'),
    ),
  );
  sl.registerLazySingleton<SoilAnalysisAIService>(
    () => SoilAnalysisAIService(sl<AiProviderConfig>(instanceName: 'soilAi')),
  );
  sl.registerLazySingleton<PlantDiseaseAIService>(
    () => PlantDiseaseAIService(sl<AiProviderConfig>(instanceName: 'diseaseAi')),
  );

  // Theme
  sl.registerFactory<ThemeCubit>(() => ThemeCubit(sl()));

  // Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));

  // Plants - Data Layer
  sl.registerLazySingleton<PlantRemoteDataSource>(
    () => PlantRemoteDataSourceImpl(sl()),
  );

  // Plants - Repository Layer
  sl.registerLazySingleton<PlantsRepository>(
    () => PlantsRepositoryImpl(sl()),
  );

  // Plants - Presentation Layer
  sl.registerFactory<PlantsBloc>(() => PlantsBloc(sl()));

  // Soil Analysis - Data Layer
  sl.registerLazySingleton<SoilAnalysisRemoteDataSource>(
    () => SoilAnalysisRemoteDataSourceImpl(sl(), sl()),
  );

  // Soil Analysis - Repository Layer
  sl.registerLazySingleton<SoilAnalysisRepository>(
    () => SoilAnalysisRepositoryImpl(sl()),
  );

  // Soil Analysis - Presentation Layer
  sl.registerFactory<SoilAnalysisBloc>(() => SoilAnalysisBloc(sl()));

  // Pest Alerts - Data Layer
  sl.registerLazySingleton<PestAlertRemoteDataSource>(
    () => PestAlertRemoteDataSourceImpl(sl()),
  );

  // Pest Alerts - Repository Layer
  sl.registerLazySingleton<PestAlertRepository>(
    () => PestAlertRepositoryImpl(sl()),
  );

  // Pest Alerts - Presentation Layer
  sl.registerFactory<PestAlertsBloc>(() => PestAlertsBloc(sl()));

  // Marketplace - Data Layer
  sl.registerLazySingleton<MarketplaceRemoteDataSource>(
    () => MarketplaceRemoteDataSourceImpl(sl()),
  );

  // Marketplace - Repository Layer
  sl.registerLazySingleton<MarketplaceRepository>(
    () => MarketplaceRepositoryImpl(sl()),
  );

  // Marketplace - Presentation Layer
  sl.registerFactory<MarketplaceBloc>(() => MarketplaceBloc(sl()));

  // Plant Disease - Data Layer
  sl.registerLazySingleton<PlantDiseaseDatasource>(
    () => PlantDiseaseDatasourceImpl(sl()),
  );

  // Plant Disease - Repository Layer
  sl.registerLazySingleton<PlantDiseaseRepository>(
    () => PlantDiseaseRepositoryImpl(sl(), sl()),
  );

  // Plant Disease - Presentation Layer
  sl.registerFactory<PlantDiseaseBloc>(() => PlantDiseaseBloc(sl()));
}
