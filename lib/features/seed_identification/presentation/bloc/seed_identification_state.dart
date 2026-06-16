part of 'seed_identification_bloc.dart';

enum SeedIdentificationStatus { initial, loading, loaded, empty, error }
enum SeedIdentificationImageStatus { initial, picking, selected, error }
enum SeedIdentificationSubmitStatus { initial, analyzing, success, error }

class SeedIdentificationState extends Equatable {
  final SeedIdentificationStatus status;
  final SeedIdentificationImageStatus imageStatus;
  final SeedIdentificationSubmitStatus submitStatus;
  final List<SeedIdentificationRecord> records;
  final String? errorMessage;
  final SeedIdentificationRecord? lastRecord;

  final Uint8List? imageBytes;
  final String? imageName;

  final double progress;
  final String progressMessage;

  const SeedIdentificationState({
    this.status = SeedIdentificationStatus.initial,
    this.imageStatus = SeedIdentificationImageStatus.initial,
    this.submitStatus = SeedIdentificationSubmitStatus.initial,
    this.records = const [],
    this.errorMessage,
    this.lastRecord,
    this.imageBytes,
    this.imageName,
    this.progress = 0.0,
    this.progressMessage = '',
  });

  bool get hasImage => imageBytes != null;
  bool get isLoading => status == SeedIdentificationStatus.loading;
  bool get isEmpty => status == SeedIdentificationStatus.empty;
  bool get isAnalyzing => submitStatus == SeedIdentificationSubmitStatus.analyzing;
  bool get isSuccess => submitStatus == SeedIdentificationSubmitStatus.success;

  SeedIdentificationState copyWith({
    SeedIdentificationStatus? status,
    SeedIdentificationImageStatus? imageStatus,
    SeedIdentificationSubmitStatus? submitStatus,
    List<SeedIdentificationRecord>? records,
    String? errorMessage,
    SeedIdentificationRecord? lastRecord,
    Uint8List? imageBytes,
    String? imageName,
    double? progress,
    String? progressMessage,
  }) {
    return SeedIdentificationState(
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

  SeedIdentificationState copyWithClearedImage() {
    return SeedIdentificationState(
      status: status,
      imageStatus: SeedIdentificationImageStatus.initial,
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
