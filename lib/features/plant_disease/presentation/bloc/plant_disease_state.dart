part of 'plant_disease_bloc.dart';

enum PlantDiseaseStatus { initial, loading, loaded, empty, error }
enum PlantDiseaseImageStatus { initial, picking, selected, error }
enum PlantDiseaseSubmitStatus { initial, analyzing, success, error }

class PlantDiseaseState extends Equatable {
  final PlantDiseaseStatus status;
  final PlantDiseaseImageStatus imageStatus;
  final PlantDiseaseSubmitStatus submitStatus;
  final List<PlantDiseaseDiagnosis> diagnoses;
  final String? errorMessage;
  final PlantDiseaseDiagnosis? lastDiagnosis;

  // Image
  final Uint8List? imageBytes;
  final String? imageName;

  const PlantDiseaseState({
    this.status = PlantDiseaseStatus.initial,
    this.imageStatus = PlantDiseaseImageStatus.initial,
    this.submitStatus = PlantDiseaseSubmitStatus.initial,
    this.diagnoses = const [],
    this.errorMessage,
    this.lastDiagnosis,
    this.imageBytes,
    this.imageName,
  });

  bool get hasImage => imageBytes != null;
  bool get isLoading => status == PlantDiseaseStatus.loading;
  bool get isEmpty => status == PlantDiseaseStatus.empty;
  bool get isAnalyzing => submitStatus == PlantDiseaseSubmitStatus.analyzing;
  bool get isSuccess => submitStatus == PlantDiseaseSubmitStatus.success;

  PlantDiseaseState copyWith({
    PlantDiseaseStatus? status,
    PlantDiseaseImageStatus? imageStatus,
    PlantDiseaseSubmitStatus? submitStatus,
    List<PlantDiseaseDiagnosis>? diagnoses,
    String? errorMessage,
    PlantDiseaseDiagnosis? lastDiagnosis,
    Uint8List? imageBytes,
    String? imageName,
  }) {
    return PlantDiseaseState(
      status: status ?? this.status,
      imageStatus: imageStatus ?? this.imageStatus,
      submitStatus: submitStatus ?? this.submitStatus,
      diagnoses: diagnoses ?? this.diagnoses,
      errorMessage: errorMessage,
      lastDiagnosis: lastDiagnosis ?? this.lastDiagnosis,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
    );
  }

  /// Returns a copy with image cleared (imageBytes = null).
  PlantDiseaseState copyWithClearedImage() {
    return PlantDiseaseState(
      status: status,
      imageStatus: PlantDiseaseImageStatus.initial,
      submitStatus: submitStatus,
      diagnoses: diagnoses,
      errorMessage: errorMessage,
      lastDiagnosis: lastDiagnosis,
      imageBytes: null,
      imageName: null,
    );
  }

  @override
  List<Object?> get props => [
        status, imageStatus, submitStatus,
        diagnoses, errorMessage, lastDiagnosis,
        imageBytes, imageName,
      ];
}
