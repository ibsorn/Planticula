import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/services/plant_identification_standalone_ai_service.dart';
import 'package:planticula/features/plant_identification/data/datasources/plant_identification_datasource.dart';
import 'package:planticula/features/plant_identification/data/models/plant_identification_model.dart';
import 'package:planticula/features/plant_identification/domain/entities/plant_identification_result.dart';
import 'package:planticula/features/plant_identification/domain/repositories/plant_identification_repository.dart';

class PlantIdentificationRepositoryImpl implements PlantIdentificationRepository {
  final PlantIdentificationDatasource _datasource;
  final PlantIdentificationStandaloneAIService _aiService;

  PlantIdentificationRepositoryImpl(this._datasource, this._aiService);

  @override
  Future<Result<List<PlantIdentificationRecord>>> getRecords() async {
    return await _datasource.getRecords();
  }

  @override
  Future<Result<PlantIdentificationRecord>> createIdentification({
    required Uint8List imageBytes,
    required String fileName,
    PlantIdProgress? onProgress,
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
    final model = PlantIdentificationModel.create(
      userId: '',
      imageUrl: imageUrl,
    );

    final createResult = await _datasource.createRecord(model);
    if (createResult is Failure<PlantIdentificationModel>) {
      await _datasource.deleteImage(imageUrl);
      return Failure(createResult.message,
          code: createResult.code, error: createResult.error);
    }

    var created = (createResult as Success<PlantIdentificationModel>).data;

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
          commonName: aiResult.commonName ?? 'Planta desconocida',
          scientificName: aiResult.scientificName,
          family: aiResult.family,
          careLevel: aiResult.careLevel,
          wateringFrequency: aiResult.wateringFrequency,
          lightRequirement: aiResult.lightRequirement,
          humidityRequirement: aiResult.humidityRequirement,
          toxicToPets: aiResult.toxicToPets,
          toxicToHumans: aiResult.toxicToHumans,
          confidenceScore: aiResult.confidenceScore ?? 0.5,
          description: aiResult.description,
          characteristics: aiResult.characteristics,
          careTips: aiResult.careTips,
          analysisNotes: aiResult.analysisNotes,
        );

        final updateResult = await _datasource.updateRecord(updated);
        if (updateResult is Success<PlantIdentificationModel>) {
          return Success(updateResult.data);
        }
        // El análisis fue correcto pero NO se pudo guardar (p. ej. una
        // constraint CHECK que no coincide). No devolvemos el registro vacío
        // como éxito (eso mostraba "Planta desconocida"); reportamos el error.
        return Failure(
          (updateResult as Failure<PlantIdentificationModel>).message,
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
    if (listResult is Success<List<PlantIdentificationModel>>) {
      final match = listResult.data.where((r) => r.id == id).firstOrNull;
      if (match != null && match.imageUrl.isNotEmpty) {
        await _datasource.deleteImage(match.imageUrl);
      }
    }
    return await _datasource.deleteRecord(id);
  }
}
