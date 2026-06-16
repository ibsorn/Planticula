import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plant_disease/data/models/plant_disease_diagnosis_model.dart';

abstract class PlantDiseaseDatasource {
  Future<Result<List<PlantDiseaseDiagnosisModel>>> getDiagnoses();
  Future<Result<PlantDiseaseDiagnosisModel>> createDiagnosisRecord(PlantDiseaseDiagnosisModel model);
  Future<Result<PlantDiseaseDiagnosisModel>> updateDiagnosis(PlantDiseaseDiagnosisModel model);
  Future<Result<void>> deleteDiagnosis(String id);
  Future<Result<String>> uploadImage(Uint8List imageBytes, String fileName);
  Future<Result<void>> deleteImage(String filePath);
}
