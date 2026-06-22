import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/soil_analysis/data/datasources/soil_analysis_remote_datasource.dart'
    show SoilAnalysisProgress;
import 'package:planticula/features/soil_analysis/domain/entities/soil_analysis.dart';

/// Contrato para el repositorio de análisis de sustrato
abstract class SoilAnalysisRepository {
  /// Obtiene todos los análisis del usuario
  Future<Result<List<SoilAnalysis>>> getAnalyses();

  /// Obtiene un análisis por su ID
  Future<Result<SoilAnalysis>> getAnalysisById(String id);

  /// Obtiene análisis de una planta específica
  Future<Result<List<SoilAnalysis>>> getAnalysesByPlant(String plantId);

  /// Crea un nuevo análisis de sustrato
  ///
  /// 1. Sube la imagen a Storage
  /// 2. Crea registro en tabla soil_analyses (status='pending')
  /// 3. Opcionalmente invoca Edge Function
  ///
  /// [onProgress] reporta el avance (0..1) en todas las etapas cuando
  /// [triggerAnalysis] es true, igual que [PlantIdentificationRepository]
  /// y [PlantDiseaseRepository]. Esto evita el modo indeterminado de la
  /// barra de progreso (animación lateral) que ocurría cuando el progreso
  /// se mantenía en 0 durante toda la subida.
  Future<Result<SoilAnalysis>> createAnalysis({
    required Uint8List imageBytes,
    required String fileName,
    String? plantId,
    bool triggerAnalysis = false,
    SoilAnalysisProgress? onProgress,
  });

  /// Actualiza un análisis existente
  Future<Result<SoilAnalysis>> updateAnalysis(SoilAnalysis analysis);

  /// Elimina un análisis (y su imagen asociada)
  Future<Result<void>> deleteAnalysis(String id);

  /// Solicita análisis de imagen con IA. [onProgress] reporta el avance (0..1).
  Future<Result<SoilAnalysis>> requestAnalysis(
    String analysisId, {
    SoilAnalysisProgress? onProgress,
  });

  /// Obtiene análisis pendientes (status='pending')
  Future<Result<List<SoilAnalysis>>> getPendingAnalyses();

  /// Obtiene análisis completados (status='completed')
  Future<Result<List<SoilAnalysis>>> getCompletedAnalyses();
}
