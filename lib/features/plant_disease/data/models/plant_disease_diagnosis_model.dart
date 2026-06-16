import 'dart:convert';
import 'package:planticula/features/plant_disease/domain/entities/plant_disease_diagnosis.dart'
    as domain;

class PlantDiseaseDiagnosisModel extends domain.PlantDiseaseDiagnosis {
  const PlantDiseaseDiagnosisModel({
    required super.id,
    required super.userId,
    super.plantId,
    required super.imageUrl,
    super.thumbnailUrl,
    super.status,
    super.analyzedAt,
    super.diagnosisType,
    super.problemName,
    super.scientificName,
    super.severity,
    super.confidenceScore,
    super.description,
    super.remedies,
    super.preventionTips,
    super.analysisNotes,
    required super.createdAt,
    super.updatedAt,
  });

  factory PlantDiseaseDiagnosisModel.fromJson(Map<String, dynamic> json) {
    // Parse remedies from JSON array stored as JSONB in DB
    List<domain.DiagnosisRemedy> remedies = [];
    final rawRemedies = json['remedies'];
    if (rawRemedies != null) {
      final list = rawRemedies is String
          ? (jsonDecode(rawRemedies) as List)
          : (rawRemedies as List);
      remedies = list.map((r) {
        final m = r as Map<String, dynamic>;
        return domain.DiagnosisRemedy(
          title: m['title'] as String,
          description: m['description'] as String,
          type: (m['type'] as String? ?? 'homemade').toRemedyType(),
          ingredients: m['ingredients'] as String?,
          instructions: m['instructions'] as String?,
          effectiveness: (m['effectiveness'] as String? ?? 'moderate')
              .toRemedyEffectiveness(),
        );
      }).toList();
    }

    return PlantDiseaseDiagnosisModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      plantId: json['plant_id'] as String?,
      imageUrl: json['image_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      status: (json['status'] as String? ?? 'pending').toDiagnosisStatus(),
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : null,
      diagnosisType: (json['diagnosis_type'] as String?)?.toDiagnosisType(),
      problemName: json['problem_name'] as String?,
      scientificName: json['scientific_name'] as String?,
      severity: (json['severity'] as String?)?.toProblemSeverity(),
      confidenceScore: json['confidence_score'] != null
          ? (json['confidence_score'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      remedies: remedies,
      preventionTips: json['prevention_tips'] as String?,
      analysisNotes: json['analysis_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final remediesJson = remedies.map((r) => {
          'title': r.title,
          'description': r.description,
          'type': r.type.name,
          'ingredients': r.ingredients,
          'instructions': r.instructions,
          'effectiveness': r.effectiveness.name,
        }).toList();

    return {
      'id': id,
      'user_id': userId,
      'plant_id': plantId,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'status': status.name,
      'analyzed_at': analyzedAt?.toIso8601String(),
      'diagnosis_type': diagnosisType?.name,
      'problem_name': problemName,
      'scientific_name': scientificName,
      'severity': severity?.name,
      'confidence_score': confidenceScore,
      'description': description,
      'remedies': remediesJson,
      'prevention_tips': preventionTips,
      'analysis_notes': analysisNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory PlantDiseaseDiagnosisModel.create({
    required String userId,
    required String imageUrl,
    String? plantId,
    String? thumbnailUrl,
  }) {
    return PlantDiseaseDiagnosisModel(
      id: '',
      userId: userId,
      plantId: plantId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      createdAt: DateTime.now(),
    );
  }

  PlantDiseaseDiagnosisModel withResults({
    required domain.DiagnosisType diagnosisType,
    required String problemName,
    String? scientificName,
    required domain.ProblemSeverity severity,
    required double confidenceScore,
    required String description,
    required List<domain.DiagnosisRemedy> remedies,
    String? preventionTips,
    String? analysisNotes,
  }) {
    return PlantDiseaseDiagnosisModel(
      id: id,
      userId: userId,
      plantId: plantId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      status: domain.DiagnosisStatus.completed,
      analyzedAt: DateTime.now(),
      diagnosisType: diagnosisType,
      problemName: problemName,
      scientificName: scientificName,
      severity: severity,
      confidenceScore: confidenceScore,
      description: description,
      remedies: remedies,
      preventionTips: preventionTips,
      analysisNotes: analysisNotes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  PlantDiseaseDiagnosisModel withError(String message) {
    return PlantDiseaseDiagnosisModel(
      id: id,
      userId: userId,
      plantId: plantId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      status: domain.DiagnosisStatus.error,
      analyzedAt: DateTime.now(),
      analysisNotes: message,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
