import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/services/seed_identification_ai_service.dart';
import 'package:planticula/features/seed_identification/data/datasources/seed_identification_datasource.dart';
import 'package:planticula/features/seed_identification/data/models/seed_identification_model.dart';
import 'package:planticula/features/seed_identification/domain/entities/seed_identification_result.dart';
import 'package:planticula/features/seed_identification/domain/repositories/seed_identification_repository.dart';

class SeedIdentificationRepositoryImpl implements SeedIdentificationRepository {
  final SeedIdentificationDatasource _datasource;
  final SeedIdentificationAIService _aiService;

  SeedIdentificationRepositoryImpl(this._datasource, this._aiService);

  @override
  Future<Result<List<SeedIdentificationRecord>>> getRecords() async {
    return await _datasource.getRecords();
  }

  @override
  Future<Result<SeedIdentificationRecord>> createIdentification({
    required Uint8List imageBytes,
    required String fileName,
    SeedIdProgress? onProgress,
  }) async {
    onProgress?.call(0.05, 'Subiendo imagen...');

    // 1. Upload image
    final uploadResult = await _datasource.uploadImage(imageBytes, fileName);
    if (uploadResult is Failure<String>) {
      return Failure(uploadResult.message,
          code: uploadResult.code, error: uploadResult.error);
    }
    final imageUrl = (uploadResult as Success<String>).data;

    onProgress?.call(0.2, 'Guardando registro...');

    // 2. Create pending record in DB
    final model = SeedIdentificationModel.create(
      userId: '',
      imageUrl: imageUrl,
    );

    final createResult = await _datasource.createRecord(model);
    if (createResult is Failure<SeedIdentificationModel>) {
      await _datasource.deleteImage(imageUrl);
      return Failure(createResult.message,
          code: createResult.code, error: createResult.error);
    }

    var created = (createResult as Success<SeedIdentificationModel>).data;

    // 3. Call AI service
    try {
      final aiResult = await _aiService.analyzeFromBytes(
        imageBytes,
        onProgress: (stage, message, progress) =>
            onProgress?.call(0.3 + 0.6 * progress, message),
      );

      onProgress?.call(0.95, 'Guardando resultados...');

      if (aiResult.isSuccessful) {
        final updated = created.withResults(
          commonName: aiResult.commonName ?? 'Semilla desconocida',
          scientificName: aiResult.scientificName,
          family: aiResult.family,
          germinationDifficulty: aiResult.germinationDifficulty,
          germinationTime: aiResult.germinationTime,
          sowingDepth: aiResult.sowingDepth,
          bestSowingSeason: aiResult.bestSowingSeason,
          confidenceScore: aiResult.confidenceScore ?? 0.5,
          description: aiResult.description,
          germinationTips: aiResult.germinationTips,
          soilRecommendation: aiResult.soilRecommendation,
          analysisNotes: aiResult.analysisNotes,
        );

        final updateResult = await _datasource.updateRecord(updated);
        if (updateResult is Success<SeedIdentificationModel>) {
          return Success(updateResult.data);
        }
        // Análisis correcto pero no se pudo guardar: reportamos el error en
        // lugar de devolver el registro vacío como éxito.
        return Failure(
          (updateResult as Failure<SeedIdentificationModel>).message,
          code: updateResult.code,
          error: updateResult.error,
        );
      } else {
        final errored = created.withError(aiResult.errorMessage ?? 'Error en análisis');
        await _datasource.updateRecord(errored);
        return Failure(aiResult.errorMessage ?? 'Error en análisis de IA');
      }
    } catch (e) {
      final errored = created.withError('Error al analizar imagen: $e');
      await _datasource.updateRecord(errored);
      return Failure('Error al analizar imagen: $e');
    }
  }

  @override
  Future<Result<void>> deleteRecord(String id) async {
    final listResult = await _datasource.getRecords();
    if (listResult is Success<List<SeedIdentificationModel>>) {
      final match = listResult.data.where((r) => r.id == id).firstOrNull;
      if (match != null && match.imageUrl.isNotEmpty) {
        await _datasource.deleteImage(match.imageUrl);
      }
    }
    return await _datasource.deleteRecord(id);
  }
}
