import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:planticula/core/ai/identification_provider.dart';
import 'package:planticula/core/ai/image_optimizer.dart';
import 'package:planticula/core/ai/result_types.dart';
import 'package:planticula/core/network/supabase_client.dart';

/// Provider that calls Supabase Edge Functions for AI analysis.
///
/// API keys live on the server (Supabase secrets) — never in the APK.
/// The Edge Function receives the base64 image and returns structured JSON.
class EdgeFunctionProvider<T> implements IdentificationProvider<T> {
  final AppSupabaseClient _supabase;
  final String _functionName;
  final T Function(Map<String, dynamic> json) _parser;
  final Map<String, dynamic> Function(Uint8List imageBytes)? _bodyBuilder;
  final ImageOptimizer _imageOptimizer;
  final Duration _timeout;

  EdgeFunctionProvider({
    required AppSupabaseClient supabase,
    required String functionName,
    required T Function(Map<String, dynamic>) parser,
    Map<String, dynamic> Function(Uint8List)? bodyBuilder,
    ImageOptimizer? imageOptimizer,
    Duration timeout = const Duration(seconds: 90),
  })  : _supabase = supabase,
        _functionName = functionName,
        _parser = parser,
        _bodyBuilder = bodyBuilder,
        _imageOptimizer = imageOptimizer ?? const ImageOptimizer(),
        _timeout = timeout;

  @override
  String get name => 'edge-function';

  @override
  bool get isAvailable => _supabase.isInitialized;

  @override
  Future<IdentificationResult<T>> identify(
    Uint8List imageBytes, {
    ProgressCallback? onProgress,
  }) async {
    if (!isAvailable) {
      return IdentificationResult.failure('Supabase no inicializado');
    }

    try {
      onProgress?.call('preparing', 'Preparando imagen...', 0.1);
      final optimized = _imageOptimizer.optimize(imageBytes);
      final base64Image = base64Encode(optimized);

      onProgress?.call('uploading', 'Enviando a análisis...', 0.3);

      final body = _bodyBuilder != null
          ? _bodyBuilder!(optimized)
          : <String, dynamic>{'image': base64Image};

      final startTime = DateTime.now();

      // Heartbeat for progress while waiting
      Timer? heartbeat;
      if (onProgress != null) {
        heartbeat = Timer.periodic(const Duration(milliseconds: 500), (_) {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          final ratio = (elapsed / 20000).clamp(0.0, 1.0);
          final p = 0.35 + 0.25 * ratio;
          onProgress(
            'analyzing',
            'Analizando${'.' * ((elapsed ~/ 1000) % 4)}',
            p,
          );
        });
      }

      final response = await _supabase.functions
          .invoke(_functionName, body: body)
          .timeout(_timeout);

      heartbeat?.cancel();

      onProgress?.call('processing', 'Procesando resultados...', 0.9);

      // Robust parsing — Supabase SDK may return Map<String, dynamic>,
      // Map<dynamic, dynamic>, or even a JSON String depending on version
      Map<String, dynamic> data;
      final rawData = response.data;
      if (rawData is String) {
        data = Map<String, dynamic>.from(jsonDecode(rawData) as Map);
      } else if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      } else {
        return IdentificationResult.failure(
          'Respuesta inesperada de Edge Function: ${rawData.runtimeType}',
        );
      }

      debugPrint('[EdgeFunctionProvider] $_functionName success=${data['success']}');

      if (data['success'] != true) {
        final error = data['error'] as String? ?? 'Error desconocido';
        debugPrint('[EdgeFunctionProvider] ERROR: $error');
        return IdentificationResult.failure(error);
      }

      final rawResult = data['result'] ?? data;
      final resultJson = rawResult is Map
          ? Map<String, dynamic>.from(rawResult)
          : <String, dynamic>{};
      debugPrint('[EdgeFunctionProvider] commonName=${resultJson['commonName']}, confidence=${resultJson['confidenceScore']}');

      final parsed = _parser(resultJson);
      final confidence = (resultJson['confidenceScore'] as num?)?.toDouble() ??
          (resultJson['score'] as num?)?.toDouble() ??
          0.7;

      onProgress?.call('completed', '¡Completado!', 1.0);

      return IdentificationResult(
        data: parsed,
        isSuccessful: true,
        providerInfo: ProviderInfo(
          name: name,
          confidence: confidence,
          latency: DateTime.now().difference(startTime),
        ),
        confidence: confidence,
      );
    } catch (e) {
      return IdentificationResult.failure('Error: ${e.toString()}');
    }
  }
}
