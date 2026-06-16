import 'package:equatable/equatable.dart';
import 'package:planticula/core/services/seed_identification_ai_service.dart';

/// Represents a single AI-powered seed identification result stored in Supabase.
class SeedIdentificationRecord extends Equatable {
  final String id;
  final String userId;

  // Image
  final String imageUrl;
  final String? thumbnailUrl;

  // AI results
  final SeedIdStatus status;
  final DateTime? analyzedAt;

  final String? commonName;
  final String? scientificName;
  final String? family;
  final SeedIdGerminationDifficulty? germinationDifficulty;
  final SeedIdGerminationTime? germinationTime;
  final SeedIdSowingDepth? sowingDepth;
  final SeedIdSowingSeason? bestSowingSeason;
  final double? confidenceScore;
  final String? description;
  final List<String> germinationTips;
  final String? soilRecommendation;
  final String? analysisNotes;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SeedIdentificationRecord({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.status = SeedIdStatus.pending,
    this.analyzedAt,
    this.commonName,
    this.scientificName,
    this.family,
    this.germinationDifficulty,
    this.germinationTime,
    this.sowingDepth,
    this.bestSowingSeason,
    this.confidenceScore,
    this.description,
    this.germinationTips = const [],
    this.soilRecommendation,
    this.analysisNotes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status == SeedIdStatus.completed;
  bool get isPending => status == SeedIdStatus.pending || status == SeedIdStatus.analyzing;
  bool get hasError => status == SeedIdStatus.error;

  String get displayName => commonName ?? 'Semilla desconocida';

  SeedIdentificationRecord copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? thumbnailUrl,
    SeedIdStatus? status,
    DateTime? analyzedAt,
    String? commonName,
    String? scientificName,
    String? family,
    SeedIdGerminationDifficulty? germinationDifficulty,
    SeedIdGerminationTime? germinationTime,
    SeedIdSowingDepth? sowingDepth,
    SeedIdSowingSeason? bestSowingSeason,
    double? confidenceScore,
    String? description,
    List<String>? germinationTips,
    String? soilRecommendation,
    String? analysisNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SeedIdentificationRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      commonName: commonName ?? this.commonName,
      scientificName: scientificName ?? this.scientificName,
      family: family ?? this.family,
      germinationDifficulty: germinationDifficulty ?? this.germinationDifficulty,
      germinationTime: germinationTime ?? this.germinationTime,
      sowingDepth: sowingDepth ?? this.sowingDepth,
      bestSowingSeason: bestSowingSeason ?? this.bestSowingSeason,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      description: description ?? this.description,
      germinationTips: germinationTips ?? this.germinationTips,
      soilRecommendation: soilRecommendation ?? this.soilRecommendation,
      analysisNotes: analysisNotes ?? this.analysisNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, imageUrl, thumbnailUrl, status, analyzedAt,
        commonName, scientificName, family, germinationDifficulty,
        germinationTime, sowingDepth, bestSowingSeason, confidenceScore,
        description, germinationTips, soilRecommendation, analysisNotes,
        createdAt, updatedAt,
      ];
}

// =============================================================================
// Enums
// =============================================================================

enum SeedIdStatus {
  pending,
  analyzing,
  completed,
  error;
}

extension SeedIdStatusExtension on String {
  SeedIdStatus toSeedIdStatus() => SeedIdStatus.values.firstWhere(
        (e) => e.name == this,
        orElse: () => SeedIdStatus.pending,
      );
}
