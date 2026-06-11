import 'package:planticula/features/soil_analysis/domain/entities/soil_analysis.dart'
    as domain;

/// Modelo de datos para SoilAnalysis - Mapeo con tabla Supabase
///
/// Tabla: soil_analyses
class SoilAnalysisModel extends domain.SoilAnalysis {
  const SoilAnalysisModel({
    required super.id,
    required super.userId,
    required super.plantId,
    required super.imageUrl,
    super.thumbnailUrl,
    super.status = domain.AnalysisStatus.pending,
    super.analyzedAt,
    super.soilType,
    super.phLevel,
    super.moistureLevel,
    super.drainageQuality,
    super.organicMatter,
    super.recommendations,
    super.analysisNotes,
    required super.createdAt,
    super.updatedAt,
  });

  /// Crea un modelo desde JSON de Supabase
  factory SoilAnalysisModel.fromJson(Map<String, dynamic> json) {
    return SoilAnalysisModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      plantId: json['plant_id'] as String? ?? '',
      imageUrl: json['image_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      status: (json['status'] as String?)?.toAnalysisStatus() ??
          domain.AnalysisStatus.pending,
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : null,
      soilType: (json['soil_type'] as String?)?.toSoilType(),
      phLevel: json['ph_level'] != null
          ? (json['ph_level'] as num).toDouble()
          : null,
      moistureLevel: (json['moisture_level'] as String?)?.toMoistureLevel(),
      drainageQuality:
          (json['drainage_quality'] as String?)?.toDrainageQuality(),
      organicMatter: (json['organic_matter'] as String?)?.toNutrientLevel(),
      recommendations: json['recommendations'] != null
          ? List<String>.from(json['recommendations'] as List)
          : null,
      analysisNotes: json['analysis_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convierte a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plant_id': plantId.isEmpty ? null : plantId,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'status': status.name,
      'analyzed_at': analyzedAt?.toIso8601String(),
      'soil_type': soilType?.name,
      'ph_level': phLevel,
      'moisture_level': moistureLevel?.name,
      'drainage_quality': drainageQuality?.name,
      'organic_matter': organicMatter?.name,
      'recommendations': recommendations,
      'analysis_notes': analysisNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Crea un modelo desde la entidad de dominio
  factory SoilAnalysisModel.fromDomain(domain.SoilAnalysis analysis) {
    return SoilAnalysisModel(
      id: analysis.id,
      userId: analysis.userId,
      plantId: analysis.plantId,
      imageUrl: analysis.imageUrl,
      thumbnailUrl: analysis.thumbnailUrl,
      status: analysis.status,
      analyzedAt: analysis.analyzedAt,
      soilType: analysis.soilType,
      phLevel: analysis.phLevel,
      moistureLevel: analysis.moistureLevel,
      drainageQuality: analysis.drainageQuality,
      organicMatter: analysis.organicMatter,
      recommendations: analysis.recommendations,
      analysisNotes: analysis.analysisNotes,
      createdAt: analysis.createdAt,
      updatedAt: analysis.updatedAt,
    );
  }

  /// Crea modelo para nuevo análisis (sin ID, timestamps se generan en DB)
  factory SoilAnalysisModel.create({
    required String userId,
    required String imageUrl,
    String plantId = '',
    String? thumbnailUrl,
  }) {
    return SoilAnalysisModel(
      id: '', // Se generará en Supabase
      userId: userId,
      plantId: plantId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      createdAt: DateTime.now(),
    );
  }

  /// Crea una copia con modificaciones
  SoilAnalysisModel copyWithModel({
    String? id,
    String? userId,
    String? plantId,
    String? imageUrl,
    String? thumbnailUrl,
    domain.AnalysisStatus? status,
    DateTime? analyzedAt,
    domain.SoilType? soilType,
    double? phLevel,
    domain.MoistureLevel? moistureLevel,
    domain.DrainageQuality? drainageQuality,
    domain.NutrientLevel? organicMatter,
    List<String>? recommendations,
    String? analysisNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoilAnalysisModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plantId: plantId ?? this.plantId,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      soilType: soilType ?? this.soilType,
      phLevel: phLevel ?? this.phLevel,
      moistureLevel: moistureLevel ?? this.moistureLevel,
      drainageQuality: drainageQuality ?? this.drainageQuality,
      organicMatter: organicMatter ?? this.organicMatter,
      recommendations: recommendations ?? this.recommendations,
      analysisNotes: analysisNotes ?? this.analysisNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Actualiza el modelo con resultados del análisis (desde Edge Function)
  SoilAnalysisModel withAnalysisResults({
    required domain.SoilType soilType,
    required double phLevel,
    required domain.MoistureLevel moistureLevel,
    required domain.DrainageQuality drainageQuality,
    required domain.NutrientLevel organicMatter,
    required List<String> recommendations,
    String? notes,
  }) {
    return copyWithModel(
      status: domain.AnalysisStatus.completed,
      analyzedAt: DateTime.now(),
      soilType: soilType,
      phLevel: phLevel,
      moistureLevel: moistureLevel,
      drainageQuality: drainageQuality,
      organicMatter: organicMatter,
      recommendations: recommendations,
      analysisNotes: notes,
    );
  }

  /// Marca como error
  SoilAnalysisModel withError(String errorMessage) {
    return copyWithModel(
      status: domain.AnalysisStatus.error,
      analysisNotes: errorMessage,
      analyzedAt: DateTime.now(),
    );
  }
}
