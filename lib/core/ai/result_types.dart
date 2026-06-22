class ProviderInfo {
  final String name;
  final double confidence;
  final Duration? latency;

  const ProviderInfo({
    required this.name,
    required this.confidence,
    this.latency,
  });

  @override
  String toString() => 'ProviderInfo($name, confidence: $confidence)';
}

class IdentificationResult<T> {
  final T? data;
  final bool isSuccessful;
  final String? errorMessage;
  final ProviderInfo providerInfo;
  final double confidence;

  const IdentificationResult({
    this.data,
    required this.isSuccessful,
    this.errorMessage,
    required this.providerInfo,
    this.confidence = 0.0,
  });

  factory IdentificationResult.success(
    T data, {
    required ProviderInfo providerInfo,
  }) =>
      IdentificationResult(
        data: data,
        isSuccessful: true,
        providerInfo: providerInfo,
        confidence: providerInfo.confidence,
      );

  factory IdentificationResult.failure(String message) =>
      IdentificationResult(
        isSuccessful: false,
        errorMessage: message,
        providerInfo: const ProviderInfo(name: 'none', confidence: 0),
      );

  factory IdentificationResult.lowConfidence() => const IdentificationResult(
        isSuccessful: false,
        errorMessage: 'No se pudo identificar con suficiente confianza',
        providerInfo: ProviderInfo(name: 'none', confidence: 0),
      );
}

class RawIdentification {
  final String? commonName;
  final String? scientificName;
  final String? family;
  final double confidence;
  final String providerName;

  const RawIdentification({
    this.commonName,
    this.scientificName,
    this.family,
    required this.confidence,
    required this.providerName,
  });
}
