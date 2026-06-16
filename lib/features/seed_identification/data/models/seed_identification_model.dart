import 'dart:convert';
import 'package:planticula/core/services/seed_identification_ai_service.dart';
import 'package:planticula/features/seed_identification/domain/entities/seed_identification_result.dart';

class SeedIdentificationModel extends SeedIdentificationRecord {
  const SeedIdentificationModel({
    required super.id,
    required super.userId,
    required super.imageUrl,
    super.thumbnailUrl,
    super.status,
    super.analyzedAt,
    super.commonName,
    super.scientificName,
    super.family,
    super.germinationDifficulty,
    super.germinationTime,
    super.sowingDepth,
    super.bestSowingSeason,
    super.confidenceScore,
    super.description,
    super.germinationTips,
    super.soilRecommendation,
    super.analysisNotes,
    required super.createdAt,
    super.updatedAt,
  });

  factory SeedIdentificationModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw) {
      if (raw == null) return [];
      final list = raw is String ? (jsonDecode(raw) as List) : (raw as List);
      return list.map((e) => e.toString()).toList();
    }

    return SeedIdentificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      status: (json['status'] as String? ?? 'pending').toSeedIdStatus(),
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : null,
      commonName: json['common_name'] as String?,
      scientificName: json['scientific_name'] as String?,
      family: json['family'] as String?,
      germinationDifficulty: _parseGerminationDifficulty(json['germination_difficulty'] as String?),
      germinationTime: _parseGerminationTime(json['germination_time'] as String?),
      sowingDepth: _parseSowingDepth(json['sowing_depth'] as String?),
      bestSowingSeason: _parseSowingSeason(json['best_sowing_season'] as String?),
      confidenceScore: json['confidence_score'] != null
          ? (json['confidence_score'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      germinationTips: parseList(json['germination_tips']),
      soilRecommendation: json['soil_recommendation'] as String?,
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
        'germination_difficulty': germinationDifficulty?.name,
        'germination_time': germinationTime?.name,
        'sowing_depth': sowingDepth?.name,
        'best_sowing_season': bestSowingSeason?.name,
        'confidence_score': confidenceScore,
        'description': description,
        'germination_tips': germinationTips,
        'soil_recommendation': soilRecommendation,
        'analysis_notes': analysisNotes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory SeedIdentificationModel.create({
    required String userId,
    required String imageUrl,
    String? thumbnailUrl,
  }) {
    return SeedIdentificationModel(
      id: '',
      userId: userId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      createdAt: DateTime.now(),
    );
  }

  SeedIdentificationModel withResults({
    required String commonName,
    String? scientificName,
    String? family,
    SeedIdGerminationDifficulty? germinationDifficulty,
    SeedIdGerminationTime? germinationTime,
    SeedIdSowingDepth? sowingDepth,
    SeedIdSowingSeason? bestSowingSeason,
    required double confidenceScore,
    String? description,
    required List<String> germinationTips,
    String? soilRecommendation,
    String? analysisNotes,
  }) {
    return SeedIdentificationModel(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      status: SeedIdStatus.completed,
      analyzedAt: DateTime.now(),
      commonName: commonName,
      scientificName: scientificName,
      family: family,
      germinationDifficulty: germinationDifficulty,
      germinationTime: germinationTime,
      sowingDepth: sowingDepth,
      bestSowingSeason: bestSowingSeason,
      confidenceScore: confidenceScore,
      description: description,
      germinationTips: germinationTips,
      soilRecommendation: soilRecommendation,
      analysisNotes: analysisNotes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  SeedIdentificationModel withError(String message) {
    return SeedIdentificationModel(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      status: SeedIdStatus.error,
      analyzedAt: DateTime.now(),
      analysisNotes: message,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static SeedIdGerminationDifficulty? _parseGerminationDifficulty(String? s) =>
      s == null ? null : SeedIdGerminationDifficulty.values.where((e) => e.name == s).firstOrNull;
  static SeedIdGerminationTime? _parseGerminationTime(String? s) =>
      s == null ? null : SeedIdGerminationTime.values.where((e) => e.name == s).firstOrNull;
  static SeedIdSowingDepth? _parseSowingDepth(String? s) =>
      s == null ? null : SeedIdSowingDepth.values.where((e) => e.name == s).firstOrNull;
  static SeedIdSowingSeason? _parseSowingSeason(String? s) =>
      s == null ? null : SeedIdSowingSeason.values.where((e) => e.name == s).firstOrNull;
}
