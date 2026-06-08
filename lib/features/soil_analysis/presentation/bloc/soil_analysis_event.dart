part of 'soil_analysis_bloc.dart';

abstract class SoilAnalysisEvent extends Equatable {
  const SoilAnalysisEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar todos los análisis del usuario
class SoilAnalysisLoadRequested extends SoilAnalysisEvent {}

/// Cargar análisis de una planta específica
class SoilAnalysisLoadByPlantRequested extends SoilAnalysisEvent {
  final String plantId;

  const SoilAnalysisLoadByPlantRequested(this.plantId);

  @override
  List<Object?> get props => [plantId];
}

/// Seleccionar imagen desde galería
class SoilAnalysisImagePickRequested extends SoilAnalysisEvent {}

/// Capturar imagen desde cámara
class SoilAnalysisImageCaptureRequested extends SoilAnalysisEvent {}

/// Subir imagen y crear análisis
class SoilAnalysisUploadRequested extends SoilAnalysisEvent {
  final String? plantId;
  final bool triggerAnalysis;

  const SoilAnalysisUploadRequested({
    this.plantId,
    this.triggerAnalysis = false,
  });

  @override
  List<Object?> get props => [plantId, triggerAnalysis];
}

/// Solicitar análisis de imagen via Edge Function
class SoilAnalysisRequestAnalysis extends SoilAnalysisEvent {
  final String analysisId;

  const SoilAnalysisRequestAnalysis(this.analysisId);

  @override
  List<Object?> get props => [analysisId];
}

/// Eliminar un análisis
class SoilAnalysisDeleteRequested extends SoilAnalysisEvent {
  final String id;

  const SoilAnalysisDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Seleccionar un análisis (para ver detalle)
class SoilAnalysisSelectRequested extends SoilAnalysisEvent {
  final String id;

  const SoilAnalysisSelectRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Limpiar error
class SoilAnalysisClearError extends SoilAnalysisEvent {}
