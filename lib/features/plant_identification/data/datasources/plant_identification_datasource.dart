import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plant_identification/data/models/plant_identification_model.dart';

abstract class PlantIdentificationDatasource {
  Future<Result<List<PlantIdentificationModel>>> getRecords();
  Future<Result<PlantIdentificationModel>> createRecord(PlantIdentificationModel model);
  Future<Result<PlantIdentificationModel>> updateRecord(PlantIdentificationModel model);
  Future<Result<void>> deleteRecord(String id);
  Future<Result<String>> uploadImage(Uint8List imageBytes, String fileName);
  Future<Result<void>> deleteImage(String filePath);
}
