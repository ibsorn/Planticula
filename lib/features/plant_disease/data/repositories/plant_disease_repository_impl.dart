import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/services/plant_disease_ai_service.dart';
import 'package:planticula/features/plant_disease/data/datasources/plant_disease_datasource.dart';
import 'package:planticula/features/plant_disease/data/models/plant_disease_diagnosis_model.dart';
import 'package:planticula/features/plant_disease/domain/entities/plant_disease_diagnosis.dart';
import 'package:planticula/features/plant_disease/domain/repositories/plant_disease_repository.dart';

class PlantDiseaseRepositoryImpl implements PlantDiseaseRepository {
  final PlantDiseaseDatasource _datasource;

  PlantDiseaseRepositoryImpl(this._datasource);

  @override
  Future<Result<List<PlantDiseaseDiagnosis>>> getDiagnoses() async {
    return await _datasource.getDiagnoses();
  }

  @override
  Future<Result<PlantDiseaseDiagnosis>> createDiagnosis({
    required Uint8List imageBytes,
    required String fileName,
    String? plantId,
  }) async {
    // 1. Upload image
    final uploadResult = await _datasource.uploadImage(imageBytes, fileName);
    if (uploadResult is Failure<String>) {
      return Failure(uploadResult.message,
          code: uploadResult.code, error: uploadResult.error);
    }
    final imageUrl = (uploadResult as Success<String>).data;

    // 2. Create pending record in DB
    final model = PlantDiseaseDiagnosisModel.create(
      userId: '', // filled by datasource
      imageUrl: imageUrl,
      plantId: plantId,
    );

    final createResult = await _datasource.createDiagnosisRecord(model);
    if (createResult is Failure<PlantDiseaseDiagnosisModel>) {
      await _datasource.deleteImage(imageUrl);
      return Failure(createResult.message,
          code: createResult.code, error: createResult.error);
    }

    var created = (createResult as Success<PlantDiseaseDiagnosisModel>).data;

    // 3. Call AI service directly (no Edge Function needed)
    try {
      // Download the image bytes from the public URL for AI analysis
      final httpResponse = await http.get(Uri.parse(imageUrl));
      final downloadedBytes = httpResponse.bodyBytes;

      final aiService = PlantDiseaseAIService();
      final aiResult = await aiService.analyzeFromBytes(downloadedBytes);

      if (aiResult.isSuccessful) {
        final updated = created.withResults(
          diagnosisType: aiResult.diagnosisType!,
          problemName: aiResult.problemName!,
          scientificName: aiResult.scientificName,
          severity: aiResult.severity!,
          confidenceScore: aiResult.confidenceScore ?? 0.7,
          description: aiResult.description ?? '',
          remedies: aiResult.remedies,
          preventionTips: aiResult.preventionTips,
          analysisNotes: aiResult.analysisNotes,
        );

        final updateResult = await _datasource.updateDiagnosis(updated);
        if (updateResult is Success<PlantDiseaseDiagnosisModel>) {
          return Success(updateResult.data);
        }
      } else {
        // Mark as error in DB but still return something useful
        final errored = created.withError(aiResult.errorMessage ?? 'Error en análisis');
        await _datasource.updateDiagnosis(errored);
        return Failure(aiResult.errorMessage ?? 'Error en análisis de IA');
      }
    } catch (e) {
      final errored = created.withError('Error al analizar imagen: $e');
      await _datasource.updateDiagnosis(errored);
      return Failure('Error al analizar imagen: $e');
    }

    return Success(created);
  }

  @override
  Future<Result<void>> deleteDiagnosis(String id) async {
    // Get the record first to delete the image too
    final listResult = await _datasource.getDiagnoses();
    if (listResult is Success<List<PlantDiseaseDiagnosisModel>>) {
      final match = listResult.data.where((d) => d.id == id).firstOrNull;
      if (match != null && match.imageUrl.isNotEmpty) {
        await _datasource.deleteImage(match.imageUrl);
      }
    }
    return await _datasource.deleteDiagnosis(id);
  }
}
