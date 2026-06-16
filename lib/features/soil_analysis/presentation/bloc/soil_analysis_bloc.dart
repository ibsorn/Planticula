import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planticula/features/soil_analysis/domain/entities/soil_analysis.dart';
import 'package:planticula/features/soil_analysis/domain/repositories/soil_analysis_repository.dart';

part 'soil_analysis_event.dart';
part 'soil_analysis_state.dart';

class SoilAnalysisBloc extends Bloc<SoilAnalysisEvent, SoilAnalysisState> {
  final SoilAnalysisRepository _repository;
  final ImagePicker _imagePicker;

  SoilAnalysisBloc(this._repository) : _imagePicker = ImagePicker(), super(const SoilAnalysisState()) {
    on<SoilAnalysisLoadRequested>(_onLoadRequested);
    on<SoilAnalysisLoadByPlantRequested>(_onLoadByPlantRequested);
    on<SoilAnalysisImagePickRequested>(_onImagePickRequested);
    on<SoilAnalysisImageCaptureRequested>(_onImageCaptureRequested);
    on<SoilAnalysisUploadRequested>(_onUploadRequested);
    on<SoilAnalysisRequestAnalysis>(_onRequestAnalysis);
    on<SoilAnalysisDeleteRequested>(_onDeleteRequested);
    on<SoilAnalysisSelectRequested>(_onSelectRequested);
    on<SoilAnalysisClearError>(_onClearError);
  }

  Future<void> _onLoadRequested(
    SoilAnalysisLoadRequested event,
    Emitter<SoilAnalysisState> emit,
  ) async {
    emit(state.copyWith(status: SoilAnalysisStatus.loading));

    final result = await _repository.getAnalyses();

    result.when(
      success: (analyses) {
        emit(state.copyWith(
          status: analyses.isEmpty
              ? SoilAnalysisStatus.empty
              : SoilAnalysisStatus.loaded,
          analyses: analyses,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          status: SoilAnalysisStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onLoadByPlantRequested(
    SoilAnalysisLoadByPlantRequested event,
    Emitter<SoilAnalysisState> emit,
  ) async {
    emit(state.copyWith(status: SoilAnalysisStatus.loading));

    final result = await _repository.getAnalysesByPlant(event.plantId);

    result.when(
      success: (analyses) {
        emit(state.copyWith(
          status: analyses.isEmpty
              ? SoilAnalysisStatus.empty
              : SoilAnalysisStatus.loaded,
          analyses: analyses,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          status: SoilAnalysisStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onImagePickRequested(
    SoilAnalysisImagePickRequested event,
    Emitter<SoilAnalysisState> emit,
  ) async {
    try {
      emit(state.copyWith(
        imageSelectionStatus: ImageSelectionStatus.picking,
      ));

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        emit(state.copyWith(
          selectedImageBytes: bytes,
          selectedImageName: pickedFile.name,
          imageSelectionStatus: ImageSelectionStatus.selected,
        ));
      } else {
        emit(state.copyWith(
          imageSelectionStatus: ImageSelectionStatus.initial,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        imageSelectionStatus: ImageSelectionStatus.error,
        errorMessage: 'Error al seleccionar imagen: ${e.toString()}',
      ));
    }
  }

  Future<void> _onImageCaptureRequested(
    SoilAnalysisImageCaptureRequested event,
    Emitter<SoilAnalysisState> emit,
  ) async {
    try {
      emit(state.copyWith(
        imageSelectionStatus: ImageSelectionStatus.picking,
      ));

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        emit(state.copyWith(
          selectedImageBytes: bytes,
          selectedImageName: pickedFile.name,
          imageSelectionStatus: ImageSelectionStatus.selected,
        ));
      } else {
        emit(state.copyWith(
          imageSelectionStatus: ImageSelectionStatus.initial,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        imageSelectionStatus: ImageSelectionStatus.error,
        errorMessage: 'Error al capturar imagen: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUploadRequested(
    SoilAnalysisUploadRequested event,
    Emitter<SoilAnalysisState> emit,
  ) async {
    if (state.selectedImageBytes == null) {
      emit(state.copyWith(
        errorMessage: 'No hay imagen seleccionada',
      ));
      return;
    }

    emit(state.copyWith(
      operationStatus: OperationStatus.uploading,
    ));

    final result = await _repository.createAnalysis(
      imageBytes: state.selectedImageBytes!,
      fileName: state.selectedImageName ?? 'soil_analysis.jpg',
      plantId: event.plantId,
      triggerAnalysis: event.triggerAnalysis,
    );

    result.when(
      success: (analysis) {
        final analyses = [analysis, ...state.analyses];

        if (event.triggerAnalysis) {
          // El análisis IA se lanzará a continuación: mantener imagen visible
          // durante el progreso; _onRequestAnalysis la limpiará al terminar.
          emit(state.copyWith(
            analyses: analyses,
            status: SoilAnalysisStatus.loaded,
            operationStatus: OperationStatus.analyzing,
            lastCreatedAnalysis: analysis,
          ));
          add(SoilAnalysisRequestAnalysis(analysis.id));
        } else {
          // Solo subida: limpiar imagen y volver a la lista.
          emit(state.copyWith(
            analyses: analyses,
            status: SoilAnalysisStatus.loaded,
            operationStatus: OperationStatus.success,
            lastCreatedAnalysis: analysis,
            selectedImageBytes: null,
            selectedImageName: null,
            imageSelectionStatus: ImageSelectionStatus.initial,
          ));
        }
      },
      failure: (message, code, error) {
        // En caso de error limpiar también la imagen para no dejar al usuario
        // bloqueado en el preview sin poder cancelar.
        emit(state.copyWith(
          operationStatus: OperationStatus.error,
          errorMessage: message,
          selectedImageBytes: null,
          selectedImageName: null,
          imageSelectionStatus: ImageSelectionStatus.initial,
        ));
      },
    );
  }

  Future<void> _onRequestAnalysis(
    SoilAnalysisRequestAnalysis event,
    Emitter<SoilAnalysisState> emit,
  ) async {
    emit(state.copyWith(
      operationStatus: OperationStatus.analyzing,
      progress: 0.0,
      progressMessage: 'Preparando análisis...',
    ));

    final result = await _repository.requestAnalysis(
      event.analysisId,
      onProgress: (progress, message) {
        if (emit.isDone) return;
        emit(state.copyWith(
          operationStatus: OperationStatus.analyzing,
          progress: progress,
          progressMessage: message,
        ));
      },
    );

    result.when(
      success: (analysis) {
        final analyses = state.analyses
            .map((a) => a.id == analysis.id ? analysis : a)
            .toList();
        emit(state.copyWith(
          analyses: analyses,
          selectedAnalysis: analysis.id == state.selectedAnalysis?.id ? analysis : state.selectedAnalysis,
          lastCreatedAnalysis: analysis,
          operationStatus: OperationStatus.success,
          // Limpiar imagen seleccionada para volver a la lista
          selectedImageBytes: null,
          selectedImageName: null,
        ));
      },
      failure: (message, code, error) {
        // Actualizar el análisis a error en la lista local
        final analyses = state.analyses.map((a) {
          if (a.id == event.analysisId) {
            return a.copyWith(
              status: AnalysisStatus.error,
              analysisNotes: message,
            );
          }
          return a;
        }).toList();

        emit(state.copyWith(
          analyses: analyses,
          operationStatus: OperationStatus.error,
          errorMessage: message,
          // Limpiar imagen también en caso de error para volver a la lista
          selectedImageBytes: null,
          selectedImageName: null,
        ));
      },
    );
  }

  Future<void> _onDeleteRequested(
    SoilAnalysisDeleteRequested event,
    Emitter<SoilAnalysisState> emit,
  ) async {
    emit(state.copyWith(
      operationStatus: OperationStatus.deleting,
    ));

    final result = await _repository.deleteAnalysis(event.id);

    result.when(
      success: (_) {
        final analyses = state.analyses.where((a) => a.id != event.id).toList();
        emit(state.copyWith(
          analyses: analyses,
          status: analyses.isEmpty ? SoilAnalysisStatus.empty : SoilAnalysisStatus.loaded,
          selectedAnalysis: state.selectedAnalysis?.id == event.id ? null : state.selectedAnalysis,
          operationStatus: OperationStatus.success,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          operationStatus: OperationStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  void _onSelectRequested(
    SoilAnalysisSelectRequested event,
    Emitter<SoilAnalysisState> emit,
  ) {
    final analysis = state.analyses.firstWhere(
      (a) => a.id == event.id,
      orElse: () => state.analyses.first,
    );
    emit(state.copyWith(selectedAnalysis: analysis));
  }

  void _onClearError(
    SoilAnalysisClearError event,
    Emitter<SoilAnalysisState> emit,
  ) {
    emit(state.copyWith(
      // Limpiar imagen seleccionada (permite cancelar el preview)
      selectedImageBytes: null,
      selectedImageName: null,
      imageSelectionStatus: ImageSelectionStatus.initial,
      // Limpiar error y resetear operationStatus
      errorMessage: null,
      operationStatus: OperationStatus.initial,
    ));
  }
}
