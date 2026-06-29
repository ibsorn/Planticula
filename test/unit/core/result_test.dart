import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/core/network/result.dart';

void main() {
  group('Success', () {
    test('isSuccess returns true', () {
      const result = Success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('data returns the wrapped value', () {
      const result = Success('hello');
      expect(result.data, equals('hello'));
    });

    test('errorMessage and errorCode return null', () {
      const result = Success(42);
      expect(result.errorMessage, isNull);
      expect(result.errorCode, isNull);
    });

    test('when calls success callback with data', () {
      const result = Success(10);
      final value = result.when(
        success: (data) => data * 2,
        failure: (msg, code, error) => -1,
      );
      expect(value, equals(20));
    });

    test('two Success with same data are equal', () {
      const a = Success(42);
      const b = Success(42);
      expect(a, equals(b));
    });

    test('two Success with different data are not equal', () {
      const a = Success(42);
      const b = Success(99);
      expect(a, isNot(equals(b)));
    });

    test('Success<void> with null is valid', () {
      const result = Success<void>(null);
      expect(result.isSuccess, isTrue);
    });

    test('Success with list data works', () {
      const result = Success<List<int>>([1, 2, 3]);
      expect(result.data, equals([1, 2, 3]));
    });
  });

  group('Failure', () {
    test('isFailure returns true', () {
      const result = Failure<int>('error');
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('data returns null', () {
      const result = Failure<int>('error');
      expect(result.data, isNull);
    });

    test('errorMessage returns the message', () {
      const result = Failure<int>('something went wrong');
      expect(result.errorMessage, equals('something went wrong'));
    });

    test('errorCode returns the code when provided', () {
      const result = Failure<int>('not found', code: '404');
      expect(result.errorCode, equals('404'));
    });

    test('errorCode returns null when not provided', () {
      const result = Failure<int>('error');
      expect(result.errorCode, isNull);
    });

    test('when calls failure callback with message, code, and error', () {
      final original = Exception('root cause');
      final result = Failure<int>('fail', code: '500', error: original);
      final value = result.when(
        success: (data) => 'ok',
        failure: (msg, code, error) => '$msg:$code',
      );
      expect(value, equals('fail:500'));
    });

    test('two Failure with same message are equal', () {
      const a = Failure<int>('err');
      const b = Failure<int>('err');
      expect(a, equals(b));
    });

    test('two Failure with different messages are not equal', () {
      const a = Failure<int>('err1');
      const b = Failure<int>('err2');
      expect(a, isNot(equals(b)));
    });

    test('Failure with code differs from Failure without code', () {
      const a = Failure<int>('err', code: '404');
      const b = Failure<int>('err');
      expect(a, isNot(equals(b)));
    });
  });

  group('Result polymorphism', () {
    test('can be used as Result<T> type', () {
      Result<int> result = const Success(42);
      expect(result.isSuccess, isTrue);

      result = const Failure('err');
      expect(result.isFailure, isTrue);
    });

    test('when is exhaustive for success and failure', () {
      Result<String> success = const Success('data');
      Result<String> failure = const Failure('error');

      expect(
        success.when(
          success: (d) => true,
          failure: (m, c, e) => false,
        ),
        isTrue,
      );
      expect(
        failure.when(
          success: (d) => true,
          failure: (m, c, e) => false,
        ),
        isFalse,
      );
    });
  });
}
