import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/soil_analysis/data/datasources/soil_analysis_remote_datasource.dart';
import 'package:planticula/features/soil_analysis/data/models/soil_analysis_model.dart';
import 'package:planticula/features/soil_analysis/domain/entities/soil_analysis.dart';
import 'package:planticula/features/soil_analysis/domain/repositories/soil_analysis_repository.dart';

/// Implementación del repositorio de análisis de sustrato
class SoilAnalysisRepositoryImpl implements SoilAnalysisRepository {
  final SoilAnalysisRemoteDataSource _dataSource;

  SoilAnalysisRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<SoilAnalysis>>> getAnalyses() async {
    return await _dataSource.getAnalyses();
  }

  @override
  Future<Result<SoilAnalysis>> getAnalysisById(String id) async {
    return await _dataSource.getAnalysisById(id);
  }

  @override
  Future<Result<List<SoilAnalysis>>> getAnalysesByPlant(String plantId) async {
    return await _dataSource.getAnalysesByPlant(plantId);
  }

  @override
  Future<Result<SoilAnalysis>> createAnalysis({
    required Uint8List imageBytes,
    required String fileName,
    String? plantId,
    bool triggerAnalysis = false,
  }) async {
    // 1. Subir imagen a Storage
    final uploadResult = await _dataSource.uploadImage(
      imageBytes,
      fileName,
      plantId: plantId,
    );

    if (uploadResult is Failure<String>) {
      return Failure(uploadResult.message,
          code: uploadResult.code, error: uploadResult.error);
    }

    final imageUrl = (uploadResult as Success<String>).data;

    // 2. Crear registro en tabla
    final analysisModel = SoilAnalysisModel.create(
      userId: '', // Se llenará en datasource
      plantId: plantId ?? '',
      imageUrl: imageUrl,
    );

    final createResult = await _dataSource.createAnalysis(analysisModel);

    if (createResult is Failure<SoilAnalysisModel>) {
      // Intentar eliminar la imagen si falló la creación del registro
      await _dataSource.deleteImage(imageUrl);
      return Failure(createResult.message,
          code: createResult.code, error: createResult.error);
    }

    final createdAnalysis = (createResult as Success<SoilAnalysisModel>).data;

    // 3. Opcionalmente invocar Edge Function
    if (triggerAnalysis) {
      final analysisResult =
          await _dataSource.analyzeImage(createdAnalysis.id);
      if (analysisResult is Success<SoilAnalysisModel>) {
        return Success(analysisResult.data);
      }
      // Si falla el análisis, aún retornamos el análisis creado
      // El usuario puede reintentar el análisis después
    }

    return Success(createdAnalysis);
  }

  @override
  Future<Result<SoilAnalysis>> updateAnalysis(SoilAnalysis analysis) async {
    final model = SoilAnalysisModel.fromDomain(analysis);
    return await _dataSource.updateAnalysis(model);
  }

  @override
  Future<Result<void>> deleteAnalysis(String id) async {
    return await _dataSource.deleteAnalysis(id);
  }

  @override
  Future<Result<SoilAnalysis>> requestAnalysis(
    String analysisId, {
    SoilAnalysisProgress? onProgress,
  }) async {
    return await _dataSource.analyzeImage(analysisId, onProgress: onProgress);
  }

  @override
  Future<Result<List<SoilAnalysis>>> getPendingAnalyses() async {
    final result = await _dataSource.getAnalyses();
    return result.when(
      success: (analyses) {
        final pending = analyses
            .where((a) => a.status == AnalysisStatus.pending)
            .toList();
        return Success(pending);
      },
      failure: (message, code, error) =>
          Failure(message, code: code, error: error),
    );
  }

  @override
  Future<Result<List<SoilAnalysis>>> getCompletedAnalyses() async {
    final result = await _dataSource.getAnalyses();
    return result.when(
      success: (analyses) {
        final completed = analyses
            .where((a) => a.status == AnalysisStatus.completed)
            .toList();
        return Success(completed);
      },
      failure: (message, code, error) =>
          Failure(message, code: code, error: error),
    );
  }
}
