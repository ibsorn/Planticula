import 'package:equatable/equatable.dart';

/// Represents a single AI-powered diagnosis of a plant health issue.
///
/// A diagnosis is created when the user submits a photo. The AI analyses
/// the image and returns the identified problem + remedies.
class PlantDiseaseDiagnosis extends Equatable {
  final String id;
  final String userId;
  final String? plantId; // Optional link to a plant in the garden

  // Image
  final String imageUrl;
  final String? thumbnailUrl;

  // AI diagnosis results
  final DiagnosisStatus status;
  final DateTime? analyzedAt;

  final DiagnosisType? diagnosisType; // pest | disease | deficiency | healthy | unknown
  final String? problemName;          // "Pulgón verde", "Oídio", "Deficiencia de hierro"
  final String? scientificName;       // Scientific name if applicable
  final ProblemSeverity? severity;    // low | medium | high | critical
  final double? confidenceScore;      // 0.0 - 1.0

  final String? description;          // Detailed description of the problem
  final List<DiagnosisRemedy> remedies; // Ordered list of remedies (homemade first)
  final String? preventionTips;       // How to prevent in the future
  final String? analysisNotes;        // General AI notes

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PlantDiseaseDiagnosis({
    required this.id,
    required this.userId,
    this.plantId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.status = DiagnosisStatus.pending,
    this.analyzedAt,
    this.diagnosisType,
    this.problemName,
    this.scientificName,
    this.severity,
    this.confidenceScore,
    this.description,
    this.remedies = const [],
    this.preventionTips,
    this.analysisNotes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status == DiagnosisStatus.completed;
  bool get isPending => status == DiagnosisStatus.pending || status == DiagnosisStatus.analyzing;
  bool get hasError => status == DiagnosisStatus.error;
  bool get isHealthy => diagnosisType == DiagnosisType.healthy;

  String get displayProblemName => problemName ?? diagnosisType?.displayName ?? 'Sin diagnóstico';

  PlantDiseaseDiagnosis copyWith({
    String? id,
    String? userId,
    String? plantId,
    String? imageUrl,
    String? thumbnailUrl,
    DiagnosisStatus? status,
    DateTime? analyzedAt,
    DiagnosisType? diagnosisType,
    String? problemName,
    String? scientificName,
    ProblemSeverity? severity,
    double? confidenceScore,
    String? description,
    List<DiagnosisRemedy>? remedies,
    String? preventionTips,
    String? analysisNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlantDiseaseDiagnosis(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plantId: plantId ?? this.plantId,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      diagnosisType: diagnosisType ?? this.diagnosisType,
      problemName: problemName ?? this.problemName,
      scientificName: scientificName ?? this.scientificName,
      severity: severity ?? this.severity,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      description: description ?? this.description,
      remedies: remedies ?? this.remedies,
      preventionTips: preventionTips ?? this.preventionTips,
      analysisNotes: analysisNotes ?? this.analysisNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, plantId, imageUrl, thumbnailUrl,
        status, analyzedAt, diagnosisType, problemName,
        scientificName, severity, confidenceScore,
        description, remedies, preventionTips, analysisNotes,
        createdAt, updatedAt,
      ];
}

// ─────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────

enum DiagnosisStatus {
  pending,
  analyzing,
  completed,
  error;
}

enum DiagnosisType {
  pest('Plaga', 'Insecto o arácnido perjudicial'),
  disease('Enfermedad', 'Hongo, bacteria o virus'),
  deficiency('Deficiencia', 'Carencia de nutrientes o agua'),
  environmentalStress('Estrés Ambiental', 'Exceso/falta de luz, temperatura'),
  healthy('Planta Sana', 'No se detectaron problemas'),
  unknown('Desconocido', 'No se pudo determinar');

  final String displayName;
  final String description;

  const DiagnosisType(this.displayName, this.description);
}

enum ProblemSeverity {
  low('Leve', 'Problema menor, vigilar', 0xFF4CAF50),
  medium('Moderado', 'Requiere atención pronto', 0xFFFF9800),
  high('Grave', 'Actuar con urgencia', 0xFFF44336),
  critical('Crítico', 'Riesgo de muerte de la planta', 0xFF9C27B0);

  final String displayName;
  final String description;
  final int colorValue;

  const ProblemSeverity(this.displayName, this.description, this.colorValue);
}

/// A single remedy for the diagnosed problem.
/// Remedies are ordered: homemade methods first, then commercial products.
class DiagnosisRemedy extends Equatable {
  final String title;
  final String description;
  final RemedyType type;
  final String? ingredients;   // For homemade remedies
  final String? instructions;  // Step-by-step instructions
  final RemedyEffectiveness effectiveness;

  const DiagnosisRemedy({
    required this.title,
    required this.description,
    required this.type,
    this.ingredients,
    this.instructions,
    this.effectiveness = RemedyEffectiveness.moderate,
  });

  @override
  List<Object?> get props => [title, description, type, ingredients, instructions, effectiveness];
}

enum RemedyType {
  homemade('Casero', '🏠'),      // Things found at home
  organic('Orgánico', '🌿'),     // Organic commercial products
  chemical('Químico', '🧪');     // Chemical commercial products

  final String displayName;
  final String emoji;

  const RemedyType(this.displayName, this.emoji);
}

enum RemedyEffectiveness {
  low('Baja'),
  moderate('Moderada'),
  high('Alta'),
  veryHigh('Muy Alta');

  final String displayName;
  const RemedyEffectiveness(this.displayName);
}

// ─────────────────────────────────────────────────────────────
// String extension parsers
// ─────────────────────────────────────────────────────────────

extension DiagnosisStatusExtension on String {
  DiagnosisStatus toDiagnosisStatus() => DiagnosisStatus.values.firstWhere(
        (e) => e.name == this,
        orElse: () => DiagnosisStatus.pending,
      );
}

extension DiagnosisTypeExtension on String {
  DiagnosisType toDiagnosisType() => DiagnosisType.values.firstWhere(
        (e) => e.name == this,
        orElse: () => DiagnosisType.unknown,
      );
}

extension ProblemSeverityExtension on String {
  ProblemSeverity toProblemSeverity() => ProblemSeverity.values.firstWhere(
        (e) => e.name == this,
        orElse: () => ProblemSeverity.medium,
      );
}

extension RemedyTypeExtension on String {
  RemedyType toRemedyType() => RemedyType.values.firstWhere(
        (e) => e.name == this,
        orElse: () => RemedyType.homemade,
      );
}

extension RemedyEffectivenessExtension on String {
  RemedyEffectiveness toRemedyEffectiveness() => RemedyEffectiveness.values.firstWhere(
        (e) => e.name == this,
        orElse: () => RemedyEffectiveness.moderate,
      );
}
