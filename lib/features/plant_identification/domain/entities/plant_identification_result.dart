import 'package:equatable/equatable.dart';
import 'package:planticula/core/services/plant_identification_standalone_ai_service.dart';

/// Represents a single AI-powered plant identification result stored in Supabase.
class PlantIdentificationRecord extends Equatable {
  final String id;
  final String userId;

  // Image
  final String imageUrl;
  final String? thumbnailUrl;

  // AI results
  final PlantIdStatus status;
  final DateTime? analyzedAt;

  final String? commonName;
  final String? scientificName;
  final String? family;
  final PlantIdCareLevel? careLevel;
  final PlantIdWateringFrequency? wateringFrequency;
  final PlantIdLightRequirement? lightRequirement;
  final PlantIdHumidityRequirement? humidityRequirement;
  final bool? toxicToPets;
  final bool? toxicToHumans;
  final double? confidenceScore;
  final String? description;
  final List<String> characteristics;
  final List<String> careTips;
  final String? analysisNotes;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PlantIdentificationRecord({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.status = PlantIdStatus.pending,
    this.analyzedAt,
    this.commonName,
    this.scientificName,
    this.family,
    this.careLevel,
    this.wateringFrequency,
    this.lightRequirement,
    this.humidityRequirement,
    this.toxicToPets,
    this.toxicToHumans,
    this.confidenceScore,
    this.description,
    this.characteristics = const [],
    this.careTips = const [],
    this.analysisNotes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status == PlantIdStatus.completed;
  bool get isPending => status == PlantIdStatus.pending || status == PlantIdStatus.analyzing;
  bool get hasError => status == PlantIdStatus.error;

  String get displayName => commonName ?? 'Planta desconocida';

  PlantIdentificationRecord copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? thumbnailUrl,
    PlantIdStatus? status,
    DateTime? analyzedAt,
    String? commonName,
    String? scientificName,
    String? family,
    PlantIdCareLevel? careLevel,
    PlantIdWateringFrequency? wateringFrequency,
    PlantIdLightRequirement? lightRequirement,
    PlantIdHumidityRequirement? humidityRequirement,
    bool? toxicToPets,
    bool? toxicToHumans,
    double? confidenceScore,
    String? description,
    List<String>? characteristics,
    List<String>? careTips,
    String? analysisNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlantIdentificationRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      commonName: commonName ?? this.commonName,
      scientificName: scientificName ?? this.scientificName,
      family: family ?? this.family,
      careLevel: careLevel ?? this.careLevel,
      wateringFrequency: wateringFrequency ?? this.wateringFrequency,
      lightRequirement: lightRequirement ?? this.lightRequirement,
      humidityRequirement: humidityRequirement ?? this.humidityRequirement,
      toxicToPets: toxicToPets ?? this.toxicToPets,
      toxicToHumans: toxicToHumans ?? this.toxicToHumans,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      description: description ?? this.description,
      characteristics: characteristics ?? this.characteristics,
      careTips: careTips ?? this.careTips,
      analysisNotes: analysisNotes ?? this.analysisNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, imageUrl, thumbnailUrl, status, analyzedAt,
        commonName, scientificName, family, careLevel, wateringFrequency,
        lightRequirement, humidityRequirement, toxicToPets, toxicToHumans,
        confidenceScore, description, characteristics, careTips, analysisNotes,
        createdAt, updatedAt,
      ];
}

// =============================================================================
// Enums
// =============================================================================

enum PlantIdStatus {
  pending,
  analyzing,
  completed,
  error;
}

extension PlantIdStatusExtension on String {
  PlantIdStatus toPlantIdStatus() => PlantIdStatus.values.firstWhere(
        (e) => e.name == this,
        orElse: () => PlantIdStatus.pending,
      );
}
