import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:planticula/core/ai/identification_provider.dart';
import 'package:planticula/core/ai/result_types.dart';

class IdentificationPipeline<T> implements IdentificationProvider<T> {
  final List<IdentificationProvider<T>> _providers;
  final double _confidenceThreshold;

  IdentificationPipeline({
    required List<IdentificationProvider<T>> providers,
    double confidenceThreshold = 0.7,
  })  : _providers = providers,
        _confidenceThreshold = confidenceThreshold;

  @override
  String get name => 'pipeline';

  @override
  bool get isAvailable => _providers.any((p) => p.isAvailable);

  @override
  Future<IdentificationResult<T>> identify(
    Uint8List imageBytes, {
    ProgressCallback? onProgress,
  }) async {
    String? lastError;
    IdentificationResult<T>? bestSuccess;

    for (final provider in _providers) {
      debugPrint('[Pipeline] Trying provider: ${provider.name} (available: ${provider.isAvailable})');
      if (!provider.isAvailable) continue;

      final result = await provider.identify(imageBytes, onProgress: onProgress);

      debugPrint('[Pipeline] ${provider.name} => success=${result.isSuccessful}, confidence=${result.confidence}');

      if (result.isSuccessful) {
        // High-confidence result → return immediately.
        if (result.confidence >= _confidenceThreshold) {
          debugPrint('[Pipeline] Returning high-confidence result from ${provider.name}');
          return result;
        }
        // Low-confidence but still successful → remember the best one so we
        // can return it if no provider reaches the threshold. Never discard a
        // valid result and report a false "could not identify" error.
        if (bestSuccess == null || result.confidence > bestSuccess.confidence) {
          bestSuccess = result;
        }
      } else {
        lastError = result.errorMessage;
      }
    }

    if (bestSuccess != null) {
      debugPrint('[Pipeline] No provider reached threshold; returning best successful result (confidence: ${bestSuccess.confidence})');
      return bestSuccess;
    }

    debugPrint('[Pipeline] All providers exhausted, lastError: $lastError');
    return IdentificationResult.failure(
      lastError ?? 'Ningún proveedor pudo identificar la imagen',
    );
  }
}
