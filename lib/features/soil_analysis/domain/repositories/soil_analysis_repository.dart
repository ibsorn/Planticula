import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
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
  Future<Result<SoilAnalysis>> createAnalysis({
    required Uint8List imageBytes,
    required String fileName,
    String? plantId,
    bool triggerAnalysis = false,
  });

  /// Actualiza un análisis existente
  Future<Result<SoilAnalysis>> updateAnalysis(SoilAnalysis analysis);

  /// Elimina un análisis (y su imagen asociada)
  Future<Result<void>> deleteAnalysis(String id);

  /// Solicita análisis de imagen via Edge Function
  Future<Result<SoilAnalysis>> requestAnalysis(String analysisId);

  /// Obtiene análisis pendientes (status='pending')
  Future<Result<List<SoilAnalysis>>> getPendingAnalyses();

  /// Obtiene análisis completados (status='completed')
  Future<Result<List<SoilAnalysis>>> getCompletedAnalyses();
}
