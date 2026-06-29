import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planticula/core/utils/image_picker_helper.dart';
import 'package:planticula/features/plant_disease/domain/entities/plant_disease_diagnosis.dart';
import 'package:planticula/features/plant_disease/domain/repositories/plant_disease_repository.dart';

part 'plant_disease_event.dart';
part 'plant_disease_state.dart';

class PlantDiseaseBloc extends Bloc<PlantDiseaseEvent, PlantDiseaseState> {
  final PlantDiseaseRepository _repository;
  final ImagePickerHelper _imagePickerHelper;

  PlantDiseaseBloc(this._repository)
      : _imagePickerHelper = ImagePickerHelper(),
        super(const PlantDiseaseState()) {
    on<PlantDiseaseLoadRequested>(_onLoadRequested);
    on<PlantDiseaseImagePickRequested>(_onImagePickRequested);
    on<PlantDiseaseImageCaptureRequested>(_onImageCaptureRequested);
    on<PlantDiseaseClearImage>(_onClearImage);
    on<PlantDiagnosisSubmitRequested>(_onSubmitRequested);
    on<PlantDiagnosisDeleteRequested>(_onDeleteRequested);
    on<PlantDiseaseClearError>(_onClearError);
  }

  Future<void> _onLoadRequested(
    PlantDiseaseLoadRequested event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    emit(state.copyWith(status: PlantDiseaseStatus.loading));

    final result = await _repository.getDiagnoses();

    result.when(
      success: (diagnoses) => emit(state.copyWith(
        status: diagnoses.isEmpty
            ? PlantDiseaseStatus.empty
            : PlantDiseaseStatus.loaded,
        diagnoses: diagnoses,
      )),
      failure: (message, code, error) => emit(state.copyWith(
        status: PlantDiseaseStatus.error,
        errorMessage: message,
      )),
    );
  }

  Future<void> _onImagePickRequested(
    PlantDiseaseImagePickRequested event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    try {
      emit(state.copyWith(imageStatus: PlantDiseaseImageStatus.picking));

      final result = await _imagePickerHelper.pickSingleImageWithName(
        source: ImageSource.gallery,
      );

      if (result != null) {
        emit(state.copyWith(
          imageBytes: result.bytes,
          imageName: result.name,
          imageStatus: PlantDiseaseImageStatus.selected,
        ));
      } else {
        emit(state.copyWith(imageStatus: PlantDiseaseImageStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        imageStatus: PlantDiseaseImageStatus.error,
        errorMessage: 'Error al seleccionar imagen: $e',
      ));
    }
  }

  Future<void> _onImageCaptureRequested(
    PlantDiseaseImageCaptureRequested event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    try {
      emit(state.copyWith(imageStatus: PlantDiseaseImageStatus.picking));

      final result = await _imagePickerHelper.pickSingleImageWithName(
        source: ImageSource.camera,
      );

      if (result != null) {
        emit(state.copyWith(
          imageBytes: result.bytes,
          imageName: result.name,
          imageStatus: PlantDiseaseImageStatus.selected,
        ));
      } else {
        emit(state.copyWith(imageStatus: PlantDiseaseImageStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        imageStatus: PlantDiseaseImageStatus.error,
        errorMessage: 'Error al capturar imagen: $e',
      ));
    }
  }

  void _onClearImage(
    PlantDiseaseClearImage event,
    Emitter<PlantDiseaseState> emit,
  ) {
    emit(state.copyWithClearedImage());
  }

  Future<void> _onSubmitRequested(
    PlantDiagnosisSubmitRequested event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    if (state.imageBytes == null) {
      emit(state.copyWith(errorMessage: 'Selecciona una imagen primero'));
      return;
    }

    emit(state.copyWith(
      submitStatus: PlantDiseaseSubmitStatus.analyzing,
      progress: 0.0,
      progressMessage: 'Preparando...',
    ));

    final result = await _repository.createDiagnosis(
      imageBytes: state.imageBytes!,
      fileName: state.imageName ?? 'disease_${DateTime.now().millisecondsSinceEpoch}.jpg',
      plantId: event.plantId,
      onProgress: (progress, message) {
        if (emit.isDone) return;
        emit(state.copyWith(
          submitStatus: PlantDiseaseSubmitStatus.analyzing,
          progress: progress,
          progressMessage: message,
        ));
      },
    );

    result.when(
      success: (diagnosis) => emit(state.copyWith(
        status: PlantDiseaseStatus.loaded,
        submitStatus: PlantDiseaseSubmitStatus.success,
        diagnoses: [diagnosis, ...state.diagnoses],
        lastDiagnosis: diagnosis,
        imageStatus: PlantDiseaseImageStatus.initial,
      ).copyWithClearedImage()),
      failure: (message, code, error) => emit(state.copyWith(
        submitStatus: PlantDiseaseSubmitStatus.error,
        errorMessage: message,
      )),
    );
  }

  Future<void> _onDeleteRequested(
    PlantDiagnosisDeleteRequested event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    final result = await _repository.deleteDiagnosis(event.id);

    result.when(
      success: (_) {
        final updated = state.diagnoses.where((d) => d.id != event.id).toList();
        emit(state.copyWith(
          diagnoses: updated,
          status: updated.isEmpty ? PlantDiseaseStatus.empty : PlantDiseaseStatus.loaded,
        ));
      },
      failure: (message, code, error) =>
          emit(state.copyWith(errorMessage: message)),
    );
  }

  void _onClearError(
    PlantDiseaseClearError event,
    Emitter<PlantDiseaseState> emit,
  ) {
    emit(state.copyWith());
  }
}
