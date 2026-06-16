import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planticula/features/seed_identification/domain/entities/seed_identification_result.dart';
import 'package:planticula/features/seed_identification/domain/repositories/seed_identification_repository.dart';

part 'seed_identification_event.dart';
part 'seed_identification_state.dart';

class SeedIdentificationBloc
    extends Bloc<SeedIdentificationEvent, SeedIdentificationState> {
  final SeedIdentificationRepository _repository;
  final ImagePicker _imagePicker;

  SeedIdentificationBloc(this._repository)
      : _imagePicker = ImagePicker(),
        super(const SeedIdentificationState()) {
    on<SeedIdentificationLoadRequested>(_onLoadRequested);
    on<SeedIdentificationImagePickRequested>(_onImagePickRequested);
    on<SeedIdentificationImageCaptureRequested>(_onImageCaptureRequested);
    on<SeedIdentificationClearImage>(_onClearImage);
    on<SeedIdentificationSubmitRequested>(_onSubmitRequested);
    on<SeedIdentificationDeleteRequested>(_onDeleteRequested);
    on<SeedIdentificationClearError>(_onClearError);
  }

  Future<void> _onLoadRequested(
    SeedIdentificationLoadRequested event,
    Emitter<SeedIdentificationState> emit,
  ) async {
    emit(state.copyWith(status: SeedIdentificationStatus.loading));

    final result = await _repository.getRecords();

    result.when(
      success: (records) => emit(state.copyWith(
        status: records.isEmpty
            ? SeedIdentificationStatus.empty
            : SeedIdentificationStatus.loaded,
        records: records,
      )),
      failure: (message, code, error) => emit(state.copyWith(
        status: SeedIdentificationStatus.error,
        errorMessage: message,
      )),
    );
  }

  Future<void> _onImagePickRequested(
    SeedIdentificationImagePickRequested event,
    Emitter<SeedIdentificationState> emit,
  ) async {
    try {
      emit(state.copyWith(imageStatus: SeedIdentificationImageStatus.picking));

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
          imageStatus: SeedIdentificationImageStatus.selected,
        ));
      } else {
        emit(state.copyWith(imageStatus: SeedIdentificationImageStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        imageStatus: SeedIdentificationImageStatus.error,
        errorMessage: 'Error al seleccionar imagen: $e',
      ));
    }
  }

  Future<void> _onImageCaptureRequested(
    SeedIdentificationImageCaptureRequested event,
    Emitter<SeedIdentificationState> emit,
  ) async {
    try {
      emit(state.copyWith(imageStatus: SeedIdentificationImageStatus.picking));

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
          imageStatus: SeedIdentificationImageStatus.selected,
        ));
      } else {
        emit(state.copyWith(imageStatus: SeedIdentificationImageStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        imageStatus: SeedIdentificationImageStatus.error,
        errorMessage: 'Error al capturar imagen: $e',
      ));
    }
  }

  void _onClearImage(
    SeedIdentificationClearImage event,
    Emitter<SeedIdentificationState> emit,
  ) {
    emit(state.copyWithClearedImage());
  }

  Future<void> _onSubmitRequested(
    SeedIdentificationSubmitRequested event,
    Emitter<SeedIdentificationState> emit,
  ) async {
    if (state.imageBytes == null) {
      emit(state.copyWith(errorMessage: 'Selecciona una imagen primero'));
      return;
    }

    emit(state.copyWith(
      submitStatus: SeedIdentificationSubmitStatus.analyzing,
      progress: 0.0,
      progressMessage: 'Preparando...',
    ));

    final result = await _repository.createIdentification(
      imageBytes: state.imageBytes!,
      fileName: state.imageName ?? 'seed_id_${DateTime.now().millisecondsSinceEpoch}.jpg',
      onProgress: (progress, message) {
        if (emit.isDone) return;
        emit(state.copyWith(
          submitStatus: SeedIdentificationSubmitStatus.analyzing,
          progress: progress,
          progressMessage: message,
        ));
      },
    );

    result.when(
      success: (record) => emit(state.copyWith(
        submitStatus: SeedIdentificationSubmitStatus.success,
        records: [record, ...state.records],
        lastRecord: record,
        imageStatus: SeedIdentificationImageStatus.initial,
      ).copyWithClearedImage()),
      failure: (message, code, error) => emit(state.copyWith(
        submitStatus: SeedIdentificationSubmitStatus.error,
        errorMessage: message,
      )),
    );
  }

  Future<void> _onDeleteRequested(
    SeedIdentificationDeleteRequested event,
    Emitter<SeedIdentificationState> emit,
  ) async {
    final result = await _repository.deleteRecord(event.id);

    result.when(
      success: (_) {
        final updated = state.records.where((r) => r.id != event.id).toList();
        emit(state.copyWith(
          records: updated,
          status: updated.isEmpty
              ? SeedIdentificationStatus.empty
              : SeedIdentificationStatus.loaded,
        ));
      },
      failure: (message, code, error) =>
          emit(state.copyWith(errorMessage: message)),
    );
  }

  void _onClearError(
    SeedIdentificationClearError event,
    Emitter<SeedIdentificationState> emit,
  ) {
    emit(state.copyWith());
  }
}
