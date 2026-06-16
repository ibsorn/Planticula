import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for a single AI function (plant ID, soil analysis, disease).
///
/// All fields are resolved exclusively from the `.env` file — nothing is
/// hardcoded.  Each function has its own set of keys so you can mix providers:
///
/// ```
/// # Shared fallback (used when function-specific keys are absent)
/// OPENROUTER_API_KEY=sk-or-v1-...
/// OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
/// OPENROUTER_MODEL=qwen/qwen3-vl-8b-instruct
///
/// # Per-function overrides (optional)
/// PLANT_ID_API_KEY=...   PLANT_ID_BASE_URL=...   PLANT_ID_MODEL=...
/// SOIL_AI_API_KEY=...    SOIL_AI_BASE_URL=...    SOIL_AI_MODEL=...
/// DISEASE_AI_API_KEY=... DISEASE_AI_BASE_URL=... DISEASE_AI_MODEL=...
/// ```
///
/// **Fallback chain (per field)**:
/// 1. Function-specific key  (e.g. `PLANT_ID_MODEL`)
/// 2. Shared key             (e.g. `OPENROUTER_MODEL`)
/// 3. `null` / empty → logs a warning at startup, feature falls back to stub
class AiProviderConfig {
  final String? apiKey;
  final String? baseUrl;
  final String? model;

  /// Human-readable name used in log messages (e.g. "Plant Identification").
  final String featureName;

  const AiProviderConfig({
    required this.featureName,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  /// Endpoint for the chat-completions call (OpenAI-compatible).
  /// Returns `null` if [baseUrl] is not configured.
  String? get chatCompletionsUrl =>
      baseUrl != null ? '$baseUrl/chat/completions' : null;

  /// Returns true if all required fields are present.
  bool get isFullyConfigured =>
      apiKey != null &&
      apiKey!.isNotEmpty &&
      baseUrl != null &&
      baseUrl!.isNotEmpty &&
      model != null &&
      model!.isNotEmpty;

  /// Returns true if an API key is available (minimum to attempt a call).
  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Factory constructors — one per AI function
  // ---------------------------------------------------------------------------

  /// Configuration for the **Plant Identification** feature.
  ///
  /// .env keys: `PLANT_ID_API_KEY`, `PLANT_ID_BASE_URL`, `PLANT_ID_MODEL`
  /// Fallbacks:  `OPENROUTER_API_KEY`, `OPENROUTER_BASE_URL`, `OPENROUTER_MODEL`
  factory AiProviderConfig.plantIdentification() =>
      _fromEnv('PLANT_ID', 'Plant Identification');

  /// Configuration for the **Soil Analysis** feature.
  ///
  /// .env keys: `SOIL_AI_API_KEY`, `SOIL_AI_BASE_URL`, `SOIL_AI_MODEL`
  /// Fallbacks:  `OPENROUTER_API_KEY`, `OPENROUTER_BASE_URL`, `OPENROUTER_MODEL`
  factory AiProviderConfig.soilAnalysis() =>
      _fromEnv('SOIL_AI', 'Soil Analysis');

  /// Configuration for the **Plant Disease Diagnosis** feature.
  ///
  /// .env keys: `DISEASE_AI_API_KEY`, `DISEASE_AI_BASE_URL`, `DISEASE_AI_MODEL`
  /// Fallbacks:  `OPENROUTER_API_KEY`, `OPENROUTER_BASE_URL`, `OPENROUTER_MODEL`
  factory AiProviderConfig.plantDisease() =>
      _fromEnv('DISEASE_AI', 'Plant Disease Diagnosis');

  // ---------------------------------------------------------------------------
  // Internal resolver
  // ---------------------------------------------------------------------------

  static AiProviderConfig _fromEnv(String prefix, String featureName) {
    final apiKey  = _pick(['${prefix}_API_KEY',  'OPENROUTER_API_KEY']);
    final baseUrl = _pick(['${prefix}_BASE_URL', 'OPENROUTER_BASE_URL']);
    final model   = _pick(['${prefix}_MODEL',    'OPENROUTER_MODEL']);

    final cfg = AiProviderConfig(
      featureName: featureName,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
    );

    if (!cfg.isFullyConfigured) {
      debugPrint(
        '[AiProviderConfig] WARNING: $featureName is not fully configured.\n'
        '  API key : ${apiKey != null ? "ok" : "MISSING"}\n'
        '  Base URL: ${baseUrl ?? "MISSING"}\n'
        '  Model   : ${model   ?? "MISSING"}\n'
        '  → Add the missing keys to your .env (see .env.example).',
      );
    }

    return cfg;
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
      'AiProviderConfig($featureName | baseUrl: $baseUrl | model: $model | hasKey: $hasApiKey)';
}
