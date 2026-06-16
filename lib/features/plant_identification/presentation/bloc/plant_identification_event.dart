part of 'plant_identification_bloc.dart';

abstract class PlantIdentificationEvent extends Equatable {
  const PlantIdentificationEvent();
  @override
  List<Object?> get props => [];
}

class PlantIdentificationLoadRequested extends PlantIdentificationEvent {}

class PlantIdentificationImagePickRequested extends PlantIdentificationEvent {}

class PlantIdentificationImageCaptureRequested extends PlantIdentificationEvent {}

class PlantIdentificationClearImage extends PlantIdentificationEvent {}

class PlantIdentificationSubmitRequested extends PlantIdentificationEvent {
  const PlantIdentificationSubmitRequested();
}

class PlantIdentificationDeleteRequested extends PlantIdentificationEvent {
  final String id;
  const PlantIdentificationDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class PlantIdentificationClearError extends PlantIdentificationEvent {}
