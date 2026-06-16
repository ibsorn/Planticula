import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for a single AI function (plant ID, soil analysis, disease).
///
/// All fields are resolved from the `.env` file.  Each function has its own
/// set of keys so you can mix providers freely:
///
/// ```
/// # Plant Identification
/// PLANT_ID_API_KEY=sk-or-v1-...
/// PLANT_ID_BASE_URL=https://openrouter.ai/api/v1
/// PLANT_ID_MODEL=qwen/qwen3-vl-8b-instruct
///
/// # Soil Analysis
/// SOIL_AI_API_KEY=hf_...
/// SOIL_AI_BASE_URL=https://api-inference.huggingface.co/v1
/// SOIL_AI_MODEL=meta-llama/Llama-3.2-11B-Vision-Instruct
///
/// # Plant Disease Diagnosis
/// DISEASE_AI_API_KEY=sk-or-v1-...
/// DISEASE_AI_BASE_URL=https://openrouter.ai/api/v1
/// DISEASE_AI_MODEL=qwen/qwen3-vl-8b-instruct
/// ```
///
/// **Fallback chain (per field)**:
/// 1. Function-specific key  (e.g. `PLANT_ID_API_KEY`)
/// 2. Shared fallback key    (e.g. `OPENROUTER_API_KEY`)
/// 3. Hard-coded default     (OpenRouter URL / qwen3-vl-8b model)
class AiProviderConfig {
  final String? apiKey;
  final String baseUrl;
  final String model;

  const AiProviderConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  /// Endpoint for the chat-completions call (OpenAI-compatible).
  String get chatCompletionsUrl => '$baseUrl/chat/completions';

  /// Returns true if an API key is available.
  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Factory constructors — one per AI function
  // ---------------------------------------------------------------------------

  /// Configuration for the **Plant Identification** feature.
  ///
  /// .env keys: `PLANT_ID_API_KEY`, `PLANT_ID_BASE_URL`, `PLANT_ID_MODEL`
  /// Fallbacks:  `OPENROUTER_API_KEY`, `OPENROUTER_BASE_URL`, `OPENROUTER_MODEL`
  factory AiProviderConfig.plantIdentification() =>
      _fromEnv('PLANT_ID', 'Planticula Plant Identification');

  /// Configuration for the **Soil Analysis** feature.
  ///
  /// .env keys: `SOIL_AI_API_KEY`, `SOIL_AI_BASE_URL`, `SOIL_AI_MODEL`
  /// Fallbacks:  `OPENROUTER_API_KEY`, `OPENROUTER_BASE_URL`, `OPENROUTER_MODEL`
  factory AiProviderConfig.soilAnalysis() =>
      _fromEnv('SOIL_AI', 'Planticula Soil Analysis');

  /// Configuration for the **Plant Disease Diagnosis** feature.
  ///
  /// .env keys: `DISEASE_AI_API_KEY`, `DISEASE_AI_BASE_URL`, `DISEASE_AI_MODEL`
  /// Fallbacks:  `OPENROUTER_API_KEY`, `OPENROUTER_BASE_URL`, `OPENROUTER_MODEL`
  factory AiProviderConfig.plantDisease() =>
      _fromEnv('DISEASE_AI', 'Planticula Plant Disease Diagnosis');

  // ---------------------------------------------------------------------------
  // Internal resolver
  // ---------------------------------------------------------------------------

  /// Resolves config for [prefix] (e.g. `PLANT_ID`) from dotenv.
  ///
  /// Per-function keys take priority; shared OpenRouter keys are the fallback.
  static AiProviderConfig _fromEnv(String prefix, String _) {
    // API key: function-specific → shared OpenRouter key
    final apiKey = _pick([
      '${prefix}_API_KEY',
      'OPENROUTER_API_KEY',
    ]);

    // Base URL: function-specific → shared → OpenRouter default
    final baseUrl = _pick([
      '${prefix}_BASE_URL',
      'OPENROUTER_BASE_URL',
    ]) ?? 'https://openrouter.ai/api/v1';

    // Model: function-specific → shared → qwen default
    final model = _pick([
      '${prefix}_MODEL',
      'OPENROUTER_MODEL',
    ]) ?? 'qwen/qwen3-vl-8b-instruct';

    return AiProviderConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
    );
  }

  /// Returns the first non-empty value found among [keys] in dotenv.
  static String? _pick(List<String> keys) {
    for (final key in keys) {
      final val = dotenv.env[key];
      if (val != null && val.isNotEmpty) return val;
    }
    return null;
  }

  @override
  String toString() =>
      'AiProviderConfig(baseUrl: $baseUrl, model: $model, hasKey: $hasApiKey)';
}
