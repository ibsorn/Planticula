import 'package:equatable/equatable.dart';

/// Entidad SoilAnalysis - Representa un análisis de sustrato/suelo
///
/// Flujo:
/// 1. Usuario selecciona/toma foto del sustrato
/// 2. Imagen se sube a Supabase Storage
/// 3. Se registra en tabla soil_analyses con status='pending'
/// 4. Edge Function procesa la imagen (futuro)
/// 5. Resultados se guardan en los campos de análisis
/// 6. Status cambia a 'completed' o 'error'
class SoilAnalysis extends Equatable {
  final String id;
  final String userId;
  final String plantId; // Opcional - asociar a planta específica

  // Información de la imagen
  final String imageUrl; // URL en Supabase Storage
  final String? thumbnailUrl; // URL de miniatura (opcional)

  // Estado del análisis
  final AnalysisStatus status;
  final DateTime? analyzedAt;

  // Resultados del análisis (populados después por Edge Function)
  final SoilType? soilType; // Tipo de sustrato
  final double? phLevel; // Nivel de pH (0-14)
  final MoistureLevel? moistureLevel; // Nivel de humedad
  final DrainageQuality? drainageQuality; // Calidad de drenaje
  final NutrientLevel? organicMatter; // Materia orgánica
  final List<String>? recommendations; // Recomendaciones generadas
  final String? analysisNotes; // Notas adicionales del análisis

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SoilAnalysis({
    required this.id,
    required this.userId,
    required this.plantId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.status = AnalysisStatus.pending,
    this.analyzedAt,
    this.soilType,
    this.phLevel,
    this.moistureLevel,
    this.drainageQuality,
    this.organicMatter,
    this.recommendations,
    this.analysisNotes,
    required this.createdAt,
    this.updatedAt,
  });

  SoilAnalysis copyWith({
    String? id,
    String? userId,
    String? plantId,
    String? imageUrl,
    String? thumbnailUrl,
    AnalysisStatus? status,
    DateTime? analyzedAt,
    SoilType? soilType,
    double? phLevel,
    MoistureLevel? moistureLevel,
    DrainageQuality? drainageQuality,
    NutrientLevel? organicMatter,
    List<String>? recommendations,
    String? analysisNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoilAnalysis(
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

  /// Indica si el análisis está completo
  bool get isCompleted => status == AnalysisStatus.completed;

  /// Indica si el análisis está pendiente
  bool get isPending => status == AnalysisStatus.pending;

  /// Indica si hay error
  bool get hasError => status == AnalysisStatus.error;

  /// Formato legible del pH
  String? get phFormatted {
    if (phLevel == null) return null;
    return phLevel!.toStringAsFixed(1);
  }

  /// Descripción del tipo de sustrato
  String? get soilTypeDescription {
    return soilType?.displayName;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        plantId,
        imageUrl,
        thumbnailUrl,
        status,
        analyzedAt,
        soilType,
        phLevel,
        moistureLevel,
        drainageQuality,
        organicMatter,
        recommendations,
        analysisNotes,
        createdAt,
        updatedAt,
      ];
}

/// Estados posibles del análisis
enum AnalysisStatus {
  pending, // Imagen subida, esperando análisis
  processing, // Edge Function está analizando
  completed, // Análisis completado con resultados
  error, // Error en el análisis
}

/// Tipos de sustrato
enum SoilType {
  sandy('Arenoso', 'Buen drenaje, poca retención de nutrientes'),
  clay('Arcilloso', 'Alta retención de agua, drenaje lento'),
  silty('Limoso', 'Buen equilibrio agua/aire'),
  loamy('Franco', 'Ideal para la mayoría de plantas'),
  peaty('Turba', 'Alta materia orgánica, ácido'),
  chalky('Calcáreo', 'Alcalino, pobre en nutrientes'),
  rocky('Rocoso', 'Drenaje excelente, poca retención'),
  pottingMix('Sustrato Universal', 'Mezcla comercial balanceada'),
  cactusMix('Sustrato para Cactus', 'Muy drenante, poca materia orgánica'),
  orchidMix('Sustrato para Orquídeas', 'Muy aireado, corteza'),
  unknown('Desconocido', 'No se pudo determinar');

  final String displayName;
  final String description;

  const SoilType(this.displayName, this.description);
}

/// Niveles de humedad
enum MoistureLevel {
  veryDry('Muy seco', 'Requiere riego inmediato'),
  dry('Seco', 'Riego recomendado'),
  slightlyDry('Ligeramente seco', 'Riego en 1-2 días'),
  optimal('Óptimo', 'Humedad adecuada'),
  moist('Húmedo', 'No regar'),
  wet('Muy húmedo', 'Riesgo de pudrición'),
  waterlogged('Encharcado', 'Peligro - mejorar drenaje');

  final String displayName;
  final String recommendation;

  const MoistureLevel(this.displayName, this.recommendation);
}

/// Calidad de drenaje
enum DrainageQuality {
  excellent('Excelente', 'Riesgo de sequía rápida'),
  good('Bueno', 'Drenaje adecuado'),
  moderate('Moderado', 'Aceptable para la mayoría'),
  poor('Deficiente', 'Riesgo de encharcamiento'),
  veryPoor('Muy deficiente', 'Peligro de pudrición de raíces');

  final String displayName;
  final String implication;

  const DrainageQuality(this.displayName, this.implication);
}

/// Niveles de nutrientes
enum NutrientLevel {
  veryLow('Muy bajo', 'Fertilización urgente necesaria'),
  low('Bajo', 'Recomendado fertilizar'),
  moderate('Moderado', 'Fertilización opcional'),
  high('Alto', 'No requiere fertilización'),
  veryHigh('Muy alto', 'Riesgo de quemar raíces');

  final String displayName;
  final String recommendation;

  const NutrientLevel(this.displayName, this.recommendation);
}

/// Extensión para parsear enums desde strings
extension AnalysisStatusExtension on String {
  AnalysisStatus? toAnalysisStatus() {
    return AnalysisStatus.values.firstWhere(
      (e) => e.name == this,
      orElse: () => AnalysisStatus.pending,
    );
  }

  SoilType? toSoilType() {
    return SoilType.values.firstWhere(
      (e) => e.name == this,
      orElse: () => SoilType.unknown,
    );
  }

  MoistureLevel? toMoistureLevel() {
    return MoistureLevel.values.firstWhere(
      (e) => e.name == this,
      orElse: () => MoistureLevel.optimal,
    );
  }

  DrainageQuality? toDrainageQuality() {
    return DrainageQuality.values.firstWhere(
      (e) => e.name == this,
      orElse: () => DrainageQuality.moderate,
    );
  }

  NutrientLevel? toNutrientLevel() {
    return NutrientLevel.values.firstWhere(
      (e) => e.name == this,
      orElse: () => NutrientLevel.moderate,
    );
  }
}
