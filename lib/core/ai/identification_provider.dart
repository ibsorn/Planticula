import 'dart:typed_data';
import 'package:planticula/core/ai/result_types.dart';

typedef ProgressCallback = void Function(
  String stage,
  String message,
  double progress,
);

abstract class IdentificationProvider<T> {
  String get name;
  bool get isAvailable;

  Future<IdentificationResult<T>> identify(
    Uint8List imageBytes, {
    ProgressCallback? onProgress,
  });
}
