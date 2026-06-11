import 'package:equatable/equatable.dart';

abstract class Result<T> extends Equatable {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => isSuccess ? (this as Success<T>).data : null;
  String? get errorMessage => isFailure ? (this as Failure<T>).message : null;
  String? get errorCode => isFailure ? (this as Failure<T>).code : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, String? code, dynamic error) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else {
      final f = this as Failure<T>;
      return failure(f.message, f.code, f.error);
    }
  }

  @override
  List<Object?> get props => [];
}

class Success<T> extends Result<T> {
  @override
  final T data;

  const Success(this.data);

  @override
  List<Object?> get props => [data];
}

class Failure<T> extends Result<T> {
  final String message;
  final String? code;
  final dynamic error;

  const Failure(this.message, {this.code, this.error});

  @override
  List<Object?> get props => [message, code, error];
}
