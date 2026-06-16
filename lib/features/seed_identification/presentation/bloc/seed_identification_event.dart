part of 'seed_identification_bloc.dart';

abstract class SeedIdentificationEvent extends Equatable {
  const SeedIdentificationEvent();
  @override
  List<Object?> get props => [];
}

class SeedIdentificationLoadRequested extends SeedIdentificationEvent {}

class SeedIdentificationImagePickRequested extends SeedIdentificationEvent {}

class SeedIdentificationImageCaptureRequested extends SeedIdentificationEvent {}

class SeedIdentificationClearImage extends SeedIdentificationEvent {}

class SeedIdentificationSubmitRequested extends SeedIdentificationEvent {
  const SeedIdentificationSubmitRequested();
}

class SeedIdentificationDeleteRequested extends SeedIdentificationEvent {
  final String id;
  const SeedIdentificationDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class SeedIdentificationClearError extends SeedIdentificationEvent {}
