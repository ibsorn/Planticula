import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:planticula/core/ai/image_optimizer.dart';
import 'package:planticula/core/ai/identification_provider.dart';
import 'package:planticula/core/ai/result_types.dart';
import 'package:planticula/core/services/ai_provider_config.dart';

class LlmVisionProvider<T> implements IdentificationProvider<T> {
  final AiProviderConfig _cfg;
  final String _prompt;
  final T Function(Map<String, dynamic> json) _parser;
  final double Function(num? raw)? _confidenceExtractor;
  final int _maxTokens;
  final double _temperature;
  final String _featureLabel;
  final ImageOptimizer _imageOptimizer;

  LlmVisionProvider({
    required AiProviderConfig config,
    required String prompt,
    required T Function(Map<String, dynamic>) parser,
    double Function(num?)? confidenceExtractor,
    int maxTokens = 1000,
    double temperature = 0.2,
    String featureLabel = 'AI Vision',
    ImageOptimizer? imageOptimizer,
  })  : _cfg = config,
        _prompt = prompt,
        _parser = parser,
        _confidenceExtractor = confidenceExtractor,
        _maxTokens = maxTokens,
        _temperature = temperature,
        _featureLabel = featureLabel,
        _imageOptimizer = imageOptimizer ?? const ImageOptimizer();

  @override
  String get name => 'llm-vision';

  @override
  bool get isAvailable => _cfg.isFullyConfigured;

  @override
  Future<IdentificationResult<T>> identify(
    Uint8List imageBytes, {
    ProgressCallback? onProgress,
  }) async {
    if (!isAvailable) {
      return IdentificationResult.failure('$_featureLabel no configurado');
    }

    try {
      onProgress?.call('preparing', 'Preparando imagen...', 0.1);
      final optimized = _imageOptimizer.optimize(imageBytes);
      final base64Image = base64Encode(optimized);

      onProgress?.call('uploading', 'Enviando a análisis...', 0.3);

      final client = http.Client();
      try {
        final request = http.Request(
          'POST',
          Uri.parse(_cfg.chatCompletionsUrl!),
        );
        request.headers.addAll({
          'Authorization': 'Bearer ${_cfg.apiKey!}',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://planticula.app',
          'X-Title': 'Planticula $_featureLabel',
        });
        request.body = jsonEncode({
          'model': _cfg.model!,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': _prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': _maxTokens,
          'temperature': _temperature,
        });

        final startTime = DateTime.now();
        final requestFuture = request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw Exception('Tiempo de espera agotado. La IA está tardando demasiado.'),
        );

        Timer? heartbeat;
        if (onProgress != null) {
          heartbeat = Timer.periodic(const Duration(milliseconds: 500), (_) {
            final elapsed = DateTime.now().difference(startTime).inMilliseconds;
            final ratio = (elapsed / 15000).clamp(0.0, 1.0);
            final p = 0.35 + 0.20 * ratio;
            onProgress(
              'analyzing',
              'La IA está analizando${'.' * ((elapsed ~/ 1000) % 4)}',
              p,
            );
          });
        }

        final streamed = await requestFuture;
        heartbeat?.cancel();

        onProgress?.call('processing', 'Procesando resultados...', 0.9);

        final response = await http.Response.fromStream(streamed);
        if (response.statusCode != 200) {
          throw Exception('AI API error ${response.statusCode}: ${response.body}');
        }

        final json = jsonDecode(response.body);
        final content =
            json['choices']?[0]?['message']?['content'] as String?;
        if (content == null || content.isEmpty) {
          throw Exception('Respuesta vacía de la IA');
        }

        onProgress?.call('completed', '¡Completado!', 1.0);

        final jsonStr = _extractJson(content);
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final parsed = _parser(data);
        final confidence = _extractConfidence(data);

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
      } finally {
        client.close();
      }
    } catch (e) {
      return IdentificationResult.failure('Error: ${e.toString()}');
    }
  }

  double _extractConfidence(Map<String, dynamic> data) {
    if (_confidenceExtractor != null) {
      return _confidenceExtractor!(
        data['confidenceScore'] as num?,
      );
    }
    return (data['confidenceScore'] as num?)?.toDouble() ?? 0.5;
  }

  String _extractJson(String text) {
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = codeBlockRegex.firstMatch(text);
    if (match != null) return match.group(1)!.trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) return text.substring(start, end + 1);
    return text.trim();
  }
}
