import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planticula/core/ai/edge_function_provider.dart';
import 'package:planticula/core/ai/identification_pipeline.dart';
import 'package:planticula/core/ai/identification_provider.dart';
import 'package:planticula/core/ai/llm_vision_provider.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/services/ai_provider_config.dart';
import 'package:planticula/core/services/location_service.dart';
import 'package:planticula/core/services/plant_disease_ai_service.dart';
import 'package:planticula/core/services/plant_identification_service.dart';
import 'package:planticula/core/services/plant_recommendation_service.dart';
import 'package:planticula/core/services/soil_analysis_ai_service.dart';
import 'package:planticula/core/services/notification_service.dart';
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
import 'package:planticula/features/plants/presentation/bloc/care_log_cubit.dart';
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
import 'package:planticula/core/services/plant_identification_standalone_ai_service.dart';
import 'package:planticula/core/services/seed_identification_ai_service.dart';
import 'package:planticula/features/plant_identification/data/datasources/plant_identification_datasource.dart';
import 'package:planticula/features/plant_identification/data/datasources/plant_identification_datasource_impl.dart';
import 'package:planticula/features/plant_identification/data/repositories/plant_identification_repository_impl.dart';
import 'package:planticula/features/plant_identification/domain/repositories/plant_identification_repository.dart';
import 'package:planticula/features/plant_identification/presentation/bloc/plant_identification_bloc.dart';
import 'package:planticula/features/seed_identification/data/datasources/seed_identification_datasource.dart';
import 'package:planticula/features/seed_identification/data/datasources/seed_identification_datasource_impl.dart';
import 'package:planticula/features/seed_identification/data/repositories/seed_identification_repository_impl.dart';
import 'package:planticula/features/seed_identification/domain/repositories/seed_identification_repository.dart';
import 'package:planticula/features/seed_identification/presentation/bloc/seed_identification_bloc.dart';
import 'package:planticula/features/locations/data/datasources/organization_remote_datasource.dart';
import 'package:planticula/features/locations/data/datasources/organization_remote_datasource_impl.dart';
import 'package:planticula/features/locations/data/datasources/location_remote_datasource.dart';
import 'package:planticula/features/locations/data/datasources/location_remote_datasource_impl.dart';
import 'package:planticula/features/locations/data/repositories/organization_repository_impl.dart';
import 'package:planticula/features/locations/data/repositories/location_repository_impl.dart';
import 'package:planticula/features/locations/domain/repositories/organization_repository.dart';
import 'package:planticula/features/locations/domain/repositories/location_repository.dart';
import 'package:planticula/features/locations/presentation/bloc/location_bloc.dart';

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
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<PlantRecommendationService>(
    () => PlantRecommendationService(),
  );

  // AI provider configs — used for LlmVisionProvider fallback (development)
  // In production, EdgeFunctionProvider is used (API keys on server)
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
  sl.registerLazySingleton<AiProviderConfig>(
    () => AiProviderConfig.plantIdentificationV2(),
    instanceName: 'plantIdV2',
  );
  sl.registerLazySingleton<AiProviderConfig>(
    () => AiProviderConfig.seedIdentification(),
    instanceName: 'seedId',
  );

  // ── AI Identification Providers ──────────────────────────────────────
  // Primary: EdgeFunctionProvider (production — API keys on Supabase)
  // Fallback: LlmVisionProvider (development — API keys in .env)

  // Plant ID V1 (Mi Jardín) — Edge Function with visual meta
  sl.registerLazySingleton<IdentificationProvider<Map<String, dynamic>>>(
    instanceName: 'plantIdV1Provider',
    () => IdentificationPipeline<Map<String, dynamic>>(
      providers: [
        EdgeFunctionProvider<Map<String, dynamic>>(
          supabase: sl(),
          functionName: 'identify-plant',
          parser: (data) => data,
          bodyBuilder: (img) => {'image': base64Encode(img), 'includeVisualMeta': true},
        ),
        LlmVisionProvider<Map<String, dynamic>>(
          config: sl(instanceName: 'plantId'),
          prompt: PlantIdentificationService.plantIdV1Prompt,
          parser: (data) => data,
          maxTokens: 1000,
          temperature: 0.3,
          featureLabel: 'Plant Identification',
        ),
      ],
    ),
  );

  // Plant ID V2 (Tools) — Edge Function ONLY (no LLM fallback for debugging)
  sl.registerLazySingleton<IdentificationProvider<PlantIdAIResult>>(
    instanceName: 'plantIdV2Provider',
    () => IdentificationPipeline<PlantIdAIResult>(
      providers: [
        EdgeFunctionProvider<PlantIdAIResult>(
          supabase: sl(),
          functionName: 'identify-plant',
          parser: PlantIdentificationStandaloneAIService.parseResult,
          bodyBuilder: (img) => {'image': base64Encode(img)},
        ),
        // LlmVisionProvider commented out to isolate EdgeFunctionProvider
        // LlmVisionProvider<PlantIdAIResult>(
        //   config: sl(instanceName: 'plantIdV2'),
        //   prompt: PlantIdentificationStandaloneAIService.plantIdPrompt,
        //   parser: PlantIdentificationStandaloneAIService.parseResult,
        //   maxTokens: 1000,
        //   featureLabel: 'Plant Identification',
        // ),
      ],
    ),
  );

  // Seed ID — Edge Function
  sl.registerLazySingleton<IdentificationProvider<SeedIdAIResult>>(
    instanceName: 'seedIdProvider',
    () => IdentificationPipeline<SeedIdAIResult>(
      providers: [
        EdgeFunctionProvider<SeedIdAIResult>(
          supabase: sl(),
          functionName: 'identify-seed',
          parser: SeedIdentificationAIService.parseResult,
        ),
        LlmVisionProvider<SeedIdAIResult>(
          config: sl(instanceName: 'seedId'),
          prompt: SeedIdentificationAIService.seedIdPrompt,
          parser: SeedIdentificationAIService.parseResult,
          maxTokens: 900,
          featureLabel: 'Seed Identification',
        ),
      ],
    ),
  );

  // Plant Disease — Edge Function
  sl.registerLazySingleton<IdentificationProvider<PlantDiseaseAIResult>>(
    instanceName: 'diseaseProvider',
    () => IdentificationPipeline<PlantDiseaseAIResult>(
      providers: [
        EdgeFunctionProvider<PlantDiseaseAIResult>(
          supabase: sl(),
          functionName: 'diagnose-disease',
          parser: PlantDiseaseAIService.parseResult,
        ),
        LlmVisionProvider<PlantDiseaseAIResult>(
          config: sl(instanceName: 'diseaseAi'),
          prompt: PlantDiseaseAIService.diseasePrompt,
          parser: PlantDiseaseAIService.parseResult,
          maxTokens: 1200,
          featureLabel: 'Plant Disease Diagnosis',
        ),
      ],
    ),
  );

  // Soil Analysis — Edge Function
  sl.registerLazySingleton<IdentificationProvider<SoilAnalysisAIResult>>(
    instanceName: 'soilProvider',
    () => IdentificationPipeline<SoilAnalysisAIResult>(
      providers: [
        EdgeFunctionProvider<SoilAnalysisAIResult>(
          supabase: sl(),
          functionName: 'analyze-soil',
          parser: SoilAnalysisAIService.parseResult,
        ),
        LlmVisionProvider<SoilAnalysisAIResult>(
          config: sl(instanceName: 'soilAi'),
          prompt: SoilAnalysisAIService.soilPrompt,
          parser: SoilAnalysisAIService.parseResult,
          maxTokens: 800,
          featureLabel: 'Soil Analysis',
        ),
      ],
    ),
  );

  // ── AI Services — receive their provider via DI ──────────────────────
  sl.registerLazySingleton<PlantIdentificationService>(
    () => PlantIdentificationService(
      sl<SpeciesService>(),
      sl<IdentificationProvider<Map<String, dynamic>>>(
          instanceName: 'plantIdV1Provider'),
    ),
  );
  sl.registerLazySingleton<SoilAnalysisAIService>(
    () => SoilAnalysisAIService(
        sl<IdentificationProvider<SoilAnalysisAIResult>>(instanceName: 'soilProvider')),
  );
  sl.registerLazySingleton<PlantDiseaseAIService>(
    () => PlantDiseaseAIService(
        sl<IdentificationProvider<PlantDiseaseAIResult>>(instanceName: 'diseaseProvider')),
  );
  sl.registerLazySingleton<PlantIdentificationStandaloneAIService>(
    () => PlantIdentificationStandaloneAIService(
        sl<IdentificationProvider<PlantIdAIResult>>(instanceName: 'plantIdV2Provider')),
  );
  sl.registerLazySingleton<SeedIdentificationAIService>(
    () => SeedIdentificationAIService(
        sl<IdentificationProvider<SeedIdAIResult>>(instanceName: 'seedIdProvider')),
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
  sl.registerFactory<PlantsBloc>(() => PlantsBloc(sl(), sl()));
  sl.registerFactory<CareLogCubit>(() => CareLogCubit(sl()));

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

  // Plant Identification V2 - Data Layer
  sl.registerLazySingleton<PlantIdentificationDatasource>(
    () => PlantIdentificationDatasourceImpl(sl()),
  );

  // Plant Identification V2 - Repository Layer
  sl.registerLazySingleton<PlantIdentificationRepository>(
    () => PlantIdentificationRepositoryImpl(sl(), sl()),
  );

  // Plant Identification V2 - Presentation Layer
  sl.registerFactory<PlantIdentificationBloc>(
    () => PlantIdentificationBloc(sl()),
  );

  // Seed Identification - Data Layer
  sl.registerLazySingleton<SeedIdentificationDatasource>(
    () => SeedIdentificationDatasourceImpl(sl()),
  );

  // Seed Identification - Repository Layer
  sl.registerLazySingleton<SeedIdentificationRepository>(
    () => SeedIdentificationRepositoryImpl(sl(), sl()),
  );

  // Seed Identification - Presentation Layer
  sl.registerFactory<SeedIdentificationBloc>(
    () => SeedIdentificationBloc(sl()),
  );

  // ── Locations & Organizations ───────────────────────────────────────────

  // Data Layer
  sl.registerLazySingleton<OrganizationRemoteDataSource>(
    () => OrganizationRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(sl()),
  );

  // Repository Layer
  sl.registerLazySingleton<OrganizationRepository>(
    () => OrganizationRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl()),
  );

  // Presentation Layer
  sl.registerFactory<LocationBloc>(() => LocationBloc(sl(), sl()));
}
