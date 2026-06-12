import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/domain/repositories/pest_alert_repository.dart';

class ReportPestUseCase {
  final PestAlertRepository _repository;
  ReportPestUseCase(this._repository);

  Future<Result<PestAlert>> call({
    Uint8List? photoBytes,
    String? fileName,
    required PestType pestType,
    String? customPestName,
    required Severity severity,
    required double latitude,
    required double longitude,
    String? locationName,
    String? notes,
  }) => _repository.reportPest(
    photoBytes: photoBytes,
    fileName: fileName,
    pestType: pestType,
    customPestName: customPestName,
    severity: severity,
    latitude: latitude,
    longitude: longitude,
    locationName: locationName,
    notes: notes,
  );
}
