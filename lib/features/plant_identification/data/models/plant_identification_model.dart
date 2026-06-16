import 'dart:convert';
import 'package:planticula/core/services/plant_identification_standalone_ai_service.dart';
import 'package:planticula/features/plant_identification/domain/entities/plant_identification_result.dart';

class PlantIdentificationModel extends PlantIdentificationRecord {
  const PlantIdentificationModel({
    required super.id,
    required super.userId,
    required super.imageUrl,
    super.thumbnailUrl,
    super.status,
    super.analyzedAt,
    super.commonName,
    super.scientificName,
    super.family,
    super.careLevel,
    super.wateringFrequency,
    super.lightRequirement,
    super.humidityRequirement,
    super.toxicToPets,
    super.toxicToHumans,
    super.confidenceScore,
    super.description,
    super.characteristics,
    super.careTips,
    super.analysisNotes,
    required super.createdAt,
    super.updatedAt,
  });

  factory PlantIdentificationModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw) {
      if (raw == null) return [];
      final list = raw is String ? (jsonDecode(raw) as List) : (raw as List);
      return list.map((e) => e.toString()).toList();
    }

    return PlantIdentificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      status: (json['status'] as String? ?? 'pending').toPlantIdStatus(),
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : null,
      commonName: json['common_name'] as String?,
      scientificName: json['scientific_name'] as String?,
      family: json['family'] as String?,
      careLevel: _parseCareLevel(json['care_level'] as String?),
      wateringFrequency: _parseWateringFrequency(json['watering_frequency'] as String?),
      lightRequirement: _parseLightRequirement(json['light_requirement'] as String?),
      humidityRequirement: _parseHumidityRequirement(json['humidity_requirement'] as String?),
      toxicToPets: json['toxic_to_pets'] as bool?,
      toxicToHumans: json['toxic_to_humans'] as bool?,
      confidenceScore: json['confidence_score'] != null
          ? (json['confidence_score'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      characteristics: parseList(json['characteristics']),
      careTips: parseList(json['care_tips']),
      analysisNotes: json['analysis_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'image_url': imageUrl,
        'thumbnail_url': thumbnailUrl,
        'status': status.name,
        'analyzed_at': analyzedAt?.toIso8601String(),
        'common_name': commonName,
        'scientific_name': scientificName,
        'family': family,
        'care_level': careLevel?.name,
        'watering_frequency': wateringFrequency?.name,
        'light_requirement': lightRequirement?.name,
        'humidity_requirement': humidityRequirement?.name,
        'toxic_to_pets': toxicToPets,
        'toxic_to_humans': toxicToHumans,
        'confidence_score': confidenceScore,
        'description': description,
        'characteristics': characteristics,
        'care_tips': careTips,
        'analysis_notes': analysisNotes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory PlantIdentificationModel.create({
    required String userId,
    required String imageUrl,
    String? thumbnailUrl,
  }) {
    return PlantIdentificationModel(
      id: '',
      userId: userId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      createdAt: DateTime.now(),
    );
  }

  PlantIdentificationModel withResults({
    required String commonName,
    String? scientificName,
    String? family,
    PlantIdCareLevel? careLevel,
    PlantIdWateringFrequency? wateringFrequency,
    PlantIdLightRequirement? lightRequirement,
    PlantIdHumidityRequirement? humidityRequirement,
    bool? toxicToPets,
    bool? toxicToHumans,
    required double confidenceScore,
    String? description,
    required List<String> characteristics,
    required List<String> careTips,
    String? analysisNotes,
  }) {
    return PlantIdentificationModel(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      status: PlantIdStatus.completed,
      analyzedAt: DateTime.now(),
      commonName: commonName,
      scientificName: scientificName,
      family: family,
      careLevel: careLevel,
      wateringFrequency: wateringFrequency,
      lightRequirement: lightRequirement,
      humidityRequirement: humidityRequirement,
      toxicToPets: toxicToPets,
      toxicToHumans: toxicToHumans,
      confidenceScore: confidenceScore,
      description: description,
      characteristics: characteristics,
      careTips: careTips,
      analysisNotes: analysisNotes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  PlantIdentificationModel withError(String message) {
    return PlantIdentificationModel(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      status: PlantIdStatus.error,
      analyzedAt: DateTime.now(),
      analysisNotes: message,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static PlantIdCareLevel? _parseCareLevel(String? s) =>
      s == null ? null : PlantIdCareLevel.values.where((e) => e.name == s).firstOrNull;
  static PlantIdWateringFrequency? _parseWateringFrequency(String? s) =>
      s == null ? null : PlantIdWateringFrequency.values.where((e) => e.name == s).firstOrNull;
  static PlantIdLightRequirement? _parseLightRequirement(String? s) =>
      s == null ? null : PlantIdLightRequirement.values.where((e) => e.name == s).firstOrNull;
  static PlantIdHumidityRequirement? _parseHumidityRequirement(String? s) =>
      s == null ? null : PlantIdHumidityRequirement.values.where((e) => e.name == s).firstOrNull;
}
