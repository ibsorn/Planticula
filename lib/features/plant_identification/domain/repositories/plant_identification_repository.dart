import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plant_identification/domain/entities/plant_identification_result.dart';

/// Reports identification progress: [progress] in 0..1, [message] human-readable.
typedef PlantIdProgress = void Function(double progress, String message);

abstract class PlantIdentificationRepository {
  Future<Result<List<PlantIdentificationRecord>>> getRecords();

  Future<Result<PlantIdentificationRecord>> createIdentification({
    required Uint8List imageBytes,
    required String fileName,
    PlantIdProgress? onProgress,
  });

  Future<Result<void>> deleteRecord(String id);
}
