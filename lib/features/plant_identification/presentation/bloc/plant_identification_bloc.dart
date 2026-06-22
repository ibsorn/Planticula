import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planticula/features/plant_identification/domain/entities/plant_identification_result.dart';
import 'package:planticula/features/plant_identification/domain/repositories/plant_identification_repository.dart';

part 'plant_identification_event.dart';
part 'plant_identification_state.dart';

class PlantIdentificationBloc
    extends Bloc<PlantIdentificationEvent, PlantIdentificationState> {
  final PlantIdentificationRepository _repository;
  final ImagePicker _imagePicker;

  PlantIdentificationBloc(this._repository)
      : _imagePicker = ImagePicker(),
        super(const PlantIdentificationState()) {
    on<PlantIdentificationLoadRequested>(_onLoadRequested);
    on<PlantIdentificationImagePickRequested>(_onImagePickRequested);
    on<PlantIdentificationImageCaptureRequested>(_onImageCaptureRequested);
    on<PlantIdentificationClearImage>(_onClearImage);
    on<PlantIdentificationSubmitRequested>(_onSubmitRequested);
    on<PlantIdentificationDeleteRequested>(_onDeleteRequested);
    on<PlantIdentificationClearError>(_onClearError);
  }

  Future<void> _onLoadRequested(
    PlantIdentificationLoadRequested event,
    Emitter<PlantIdentificationState> emit,
  ) async {
    emit(state.copyWith(status: PlantIdentificationStatus.loading));

    final result = await _repository.getRecords();

    result.when(
      success: (records) => emit(state.copyWith(
        status: records.isEmpty
            ? PlantIdentificationStatus.empty
            : PlantIdentificationStatus.loaded,
        records: records,
      )),
      failure: (message, code, error) => emit(state.copyWith(
        status: PlantIdentificationStatus.error,
        errorMessage: message,
      )),
    );
  }

  Future<void> _onImagePickRequested(
    PlantIdentificationImagePickRequested event,
    Emitter<PlantIdentificationState> emit,
  ) async {
    try {
      emit(state.copyWith(imageStatus: PlantIdentificationImageStatus.picking));

      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        emit(state.copyWith(
          imageBytes: bytes,
          imageName: file.name,
          imageStatus: PlantIdentificationImageStatus.selected,
        ));
      } else {
        emit(state.copyWith(imageStatus: PlantIdentificationImageStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        imageStatus: PlantIdentificationImageStatus.error,
        errorMessage: 'Error al seleccionar imagen: $e',
      ));
    }
  }

  Future<void> _onImageCaptureRequested(
    PlantIdentificationImageCaptureRequested event,
    Emitter<PlantIdentificationState> emit,
  ) async {
    try {
      emit(state.copyWith(imageStatus: PlantIdentificationImageStatus.picking));

      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        emit(state.copyWith(
          imageBytes: bytes,
          imageName: file.name,
          imageStatus: PlantIdentificationImageStatus.selected,
        ));
      } else {
        emit(state.copyWith(imageStatus: PlantIdentificationImageStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        imageStatus: PlantIdentificationImageStatus.error,
        errorMessage: 'Error al capturar imagen: $e',
      ));
    }
  }

  void _onClearImage(
    PlantIdentificationClearImage event,
    Emitter<PlantIdentificationState> emit,
  ) {
    emit(state.copyWithClearedImage());
  }

  Future<void> _onSubmitRequested(
    PlantIdentificationSubmitRequested event,
    Emitter<PlantIdentificationState> emit,
  ) async {
    if (state.imageBytes == null) {
      emit(state.copyWith(errorMessage: 'Selecciona una imagen primero'));
      return;
    }

    emit(state.copyWith(
      submitStatus: PlantIdentificationSubmitStatus.analyzing,
      progress: 0.0,
      progressMessage: 'Preparando...',
    ));

    final result = await _repository.createIdentification(
      imageBytes: state.imageBytes!,
      fileName: state.imageName ?? 'plant_id_${DateTime.now().millisecondsSinceEpoch}.jpg',
      onProgress: (progress, message) {
        if (emit.isDone) return;
        emit(state.copyWith(
          submitStatus: PlantIdentificationSubmitStatus.analyzing,
          progress: progress,
          progressMessage: message,
        ));
      },
    );

    result.when(
      success: (record) => emit(state.copyWith(
        status: PlantIdentificationStatus.loaded,
        submitStatus: PlantIdentificationSubmitStatus.success,
        records: [record, ...state.records],
        lastRecord: record,
        imageStatus: PlantIdentificationImageStatus.initial,
      ).copyWithClearedImage()),
      failure: (message, code, error) => emit(state.copyWith(
        submitStatus: PlantIdentificationSubmitStatus.error,
        errorMessage: message,
      )),
    );
  }

  Future<void> _onDeleteRequested(
    PlantIdentificationDeleteRequested event,
    Emitter<PlantIdentificationState> emit,
  ) async {
    final result = await _repository.deleteRecord(event.id);

    result.when(
      success: (_) {
        final updated = state.records.where((r) => r.id != event.id).toList();
        emit(state.copyWith(
          records: updated,
          status: updated.isEmpty
              ? PlantIdentificationStatus.empty
              : PlantIdentificationStatus.loaded,
        ));
      },
      failure: (message, code, error) =>
          emit(state.copyWith(errorMessage: message)),
    );
  }

  void _onClearError(
    PlantIdentificationClearError event,
    Emitter<PlantIdentificationState> emit,
  ) {
    emit(state.copyWith());
  }
}
