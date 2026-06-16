part of 'plant_disease_bloc.dart';

abstract class PlantDiseaseEvent extends Equatable {
  const PlantDiseaseEvent();
  @override
  List<Object?> get props => [];
}

class PlantDiseaseLoadRequested extends PlantDiseaseEvent {}

class PlantDiseaseImagePickRequested extends PlantDiseaseEvent {}

class PlantDiseaseImageCaptureRequested extends PlantDiseaseEvent {}

class PlantDiseaseClearImage extends PlantDiseaseEvent {}

class PlantDiagnosisSubmitRequested extends PlantDiseaseEvent {
  final String? plantId;

  const PlantDiagnosisSubmitRequested({this.plantId});

  @override
  List<Object?> get props => [plantId];
}

class PlantDiagnosisDeleteRequested extends PlantDiseaseEvent {
  final String id;

  const PlantDiagnosisDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class PlantDiseaseClearError extends PlantDiseaseEvent {}
