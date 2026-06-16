part of 'soil_analysis_bloc.dart';

enum SoilAnalysisStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

enum ImageSelectionStatus {
  initial,
  picking,
  selected,
  error,
}

enum OperationStatus {
  initial,
  uploading,
  analyzing,
  deleting,
  success,
  error,
}

class SoilAnalysisState extends Equatable {
  final SoilAnalysisStatus status;
  final ImageSelectionStatus imageSelectionStatus;
  final OperationStatus operationStatus;
  final List<SoilAnalysis> analyses;
  final String? errorMessage;
  final SoilAnalysis? selectedAnalysis;
  final SoilAnalysis? lastCreatedAnalysis;

  // Image selection
  final Uint8List? selectedImageBytes;
  final String? selectedImageName;

  // Analysis progress (0..1) and current stage message
  final double progress;
  final String progressMessage;

  const SoilAnalysisState({
    this.status = SoilAnalysisStatus.initial,
    this.imageSelectionStatus = ImageSelectionStatus.initial,
    this.operationStatus = OperationStatus.initial,
    this.analyses = const [],
    this.errorMessage,
    this.selectedAnalysis,
    this.lastCreatedAnalysis,
    this.selectedImageBytes,
    this.selectedImageName,
    this.progress = 0.0,
    this.progressMessage = '',
  });

  bool get isLoading => status == SoilAnalysisStatus.loading;
  bool get isEmpty => status == SoilAnalysisStatus.empty;
  bool get hasError => status == SoilAnalysisStatus.error;
  bool get hasImageSelected => selectedImageBytes != null;
  bool get isUploading => operationStatus == OperationStatus.uploading;
  bool get isAnalyzing => operationStatus == OperationStatus.analyzing;
  bool get isDeleting => operationStatus == OperationStatus.deleting;
  bool get isOperationSuccess => operationStatus == OperationStatus.success;

  /// Análisis completados
  List<SoilAnalysis> get completedAnalyses => analyses
      .where((a) => a.status == AnalysisStatus.completed)
      .toList();

  /// Análisis pendientes
  List<SoilAnalysis> get pendingAnalyses => analyses
      .where((a) => a.status == AnalysisStatus.pending || a.status == AnalysisStatus.processing)
      .toList();

  SoilAnalysisState copyWith({
    SoilAnalysisStatus? status,
    ImageSelectionStatus? imageSelectionStatus,
    OperationStatus? operationStatus,
    List<SoilAnalysis>? analyses,
    String? errorMessage,
    SoilAnalysis? selectedAnalysis,
    SoilAnalysis? lastCreatedAnalysis,
    Uint8List? selectedImageBytes,
    String? selectedImageName,
    double? progress,
    String? progressMessage,
  }) {
    return SoilAnalysisState(
      status: status ?? this.status,
      imageSelectionStatus: imageSelectionStatus ?? this.imageSelectionStatus,
      operationStatus: operationStatus ?? this.operationStatus,
      analyses: analyses ?? this.analyses,
      errorMessage: errorMessage,
      selectedAnalysis: selectedAnalysis ?? this.selectedAnalysis,
      lastCreatedAnalysis: lastCreatedAnalysis ?? this.lastCreatedAnalysis,
      selectedImageBytes: selectedImageBytes ?? this.selectedImageBytes,
      selectedImageName: selectedImageName ?? this.selectedImageName,
      progress: progress ?? this.progress,
      progressMessage: progressMessage ?? this.progressMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        imageSelectionStatus,
        operationStatus,
        analyses,
        errorMessage,
        selectedAnalysis,
        lastCreatedAnalysis,
        selectedImageBytes,
        selectedImageName,
        progress,
        progressMessage,
      ];
}
