part of 'plant_identification_bloc.dart';

enum PlantIdentificationStatus { initial, loading, loaded, empty, error }
enum PlantIdentificationImageStatus { initial, picking, selected, error }
enum PlantIdentificationSubmitStatus { initial, analyzing, success, error }

class PlantIdentificationState extends Equatable {
  final PlantIdentificationStatus status;
  final PlantIdentificationImageStatus imageStatus;
  final PlantIdentificationSubmitStatus submitStatus;
  final List<PlantIdentificationRecord> records;
  final String? errorMessage;
  final PlantIdentificationRecord? lastRecord;

  final Uint8List? imageBytes;
  final String? imageName;

  final double progress;
  final String progressMessage;

  const PlantIdentificationState({
    this.status = PlantIdentificationStatus.initial,
    this.imageStatus = PlantIdentificationImageStatus.initial,
    this.submitStatus = PlantIdentificationSubmitStatus.initial,
    this.records = const [],
    this.errorMessage,
    this.lastRecord,
    this.imageBytes,
    this.imageName,
    this.progress = 0.0,
    this.progressMessage = '',
  });

  bool get hasImage => imageBytes != null;
  bool get isLoading => status == PlantIdentificationStatus.loading;
  bool get isEmpty => records.isEmpty;
  bool get isAnalyzing => submitStatus == PlantIdentificationSubmitStatus.analyzing;
  bool get isSuccess => submitStatus == PlantIdentificationSubmitStatus.success;

  PlantIdentificationState copyWith({
    PlantIdentificationStatus? status,
    PlantIdentificationImageStatus? imageStatus,
    PlantIdentificationSubmitStatus? submitStatus,
    List<PlantIdentificationRecord>? records,
    String? errorMessage,
    PlantIdentificationRecord? lastRecord,
    Uint8List? imageBytes,
    String? imageName,
    double? progress,
    String? progressMessage,
  }) {
    return PlantIdentificationState(
      status: status ?? this.status,
      imageStatus: imageStatus ?? this.imageStatus,
      submitStatus: submitStatus ?? this.submitStatus,
      records: records ?? this.records,
      errorMessage: errorMessage,
      lastRecord: lastRecord ?? this.lastRecord,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      progress: progress ?? this.progress,
      progressMessage: progressMessage ?? this.progressMessage,
    );
  }

  PlantIdentificationState copyWithClearedImage() {
    return PlantIdentificationState(
      status: status,
      imageStatus: PlantIdentificationImageStatus.initial,
      submitStatus: submitStatus,
      records: records,
      errorMessage: errorMessage,
      lastRecord: lastRecord,
      imageBytes: null,
      imageName: null,
      progress: 0.0,
      progressMessage: '',
    );
  }

  @override
  List<Object?> get props => [
        status, imageStatus, submitStatus,
        records, errorMessage, lastRecord,
        imageBytes, imageName, progress, progressMessage,
      ];
}
