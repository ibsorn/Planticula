import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plant_disease/domain/entities/plant_disease_diagnosis.dart';

abstract class PlantDiseaseRepository {
  /// Returns all diagnoses for the current user, ordered by date desc.
  Future<Result<List<PlantDiseaseDiagnosis>>> getDiagnoses();

  /// Creates a diagnosis: uploads image + calls AI + saves result.
  Future<Result<PlantDiseaseDiagnosis>> createDiagnosis({
    required Uint8List imageBytes,
    required String fileName,
    String? plantId,
  });

  /// Deletes a diagnosis and its associated image.
  Future<Result<void>> deleteDiagnosis(String id);
}
