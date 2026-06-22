import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/soil_analysis/data/models/soil_analysis_model.dart';

/// Reports analysis progress: [progress] in 0..1, [message] human-readable.
typedef SoilAnalysisProgress = void Function(double progress, String message);

/// Contrato para la fuente de datos de análisis de sustrato
abstract class SoilAnalysisRemoteDataSource {
  /// Obtiene todos los análisis del usuario
  Future<Result<List<SoilAnalysisModel>>> getAnalyses();

  /// Obtiene un análisis por su ID
  Future<Result<SoilAnalysisModel>> getAnalysisById(String id);

  /// Obtiene análisis de una planta específica
  Future<Result<List<SoilAnalysisModel>>> getAnalysesByPlant(String plantId);

  /// Crea un nuevo registro de análisis
  Future<Result<SoilAnalysisModel>> createAnalysis(SoilAnalysisModel analysis);

  /// Actualiza un análisis existente
  Future<Result<SoilAnalysisModel>> updateAnalysis(SoilAnalysisModel analysis);

  /// Elimina un análisis
  Future<Result<void>> deleteAnalysis(String id);

  /// Sube imagen a Supabase Storage
  /// Retorna la URL pública de la imagen subida
  Future<Result<String>> uploadImage(
    Uint8List imageBytes,
    String fileName, {
    String? plantId,
  });

  /// Elimina imagen de Supabase Storage
  Future<Result<void>> deleteImage(String filePath);

  /// Analiza la imagen con IA y retorna el análisis completado.
  /// [imageBytes] son los bytes de la imagen ya en memoria.
  /// [onProgress] reporta el avance del análisis (0..1).
  Future<Result<SoilAnalysisModel>> analyzeImage(
    String analysisId,
    Uint8List imageBytes, {
    SoilAnalysisProgress? onProgress,
  });
}
