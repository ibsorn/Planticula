import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/seed_identification/data/models/seed_identification_model.dart';

abstract class SeedIdentificationDatasource {
  Future<Result<List<SeedIdentificationModel>>> getRecords();
  Future<Result<SeedIdentificationModel>> createRecord(SeedIdentificationModel model);
  Future<Result<SeedIdentificationModel>> updateRecord(SeedIdentificationModel model);
  Future<Result<void>> deleteRecord(String id);
  Future<Result<String>> uploadImage(Uint8List imageBytes, String fileName);
  Future<Result<void>> deleteImage(String filePath);
}
