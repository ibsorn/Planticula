import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/seed_identification/domain/entities/seed_identification_result.dart';

/// Reports identification progress: [progress] in 0..1, [message] human-readable.
typedef SeedIdProgress = void Function(double progress, String message);

abstract class SeedIdentificationRepository {
  Future<Result<List<SeedIdentificationRecord>>> getRecords();

  Future<Result<SeedIdentificationRecord>> createIdentification({
    required Uint8List imageBytes,
    required String fileName,
    SeedIdProgress? onProgress,
  });

  Future<Result<void>> deleteRecord(String id);
}
