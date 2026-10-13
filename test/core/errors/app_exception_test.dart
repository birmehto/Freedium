import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/errors/app_exception.dart';

void main() {
  group('AppException', () {
    test('default user message for each error type', () {
      expect(
        AppException.invalidUrl().userMessage,
        'Please enter a valid URL.',
      );
      expect(
        AppException.network().userMessage,
        'Network error. Please check your internet connection.',
      );
      expect(
        AppException.timeout().userMessage,
        'Request timed out. Please try again.',
      );
      expect(
        AppException.articleNotFound().userMessage,
        'Article not found. It may have been removed.',
      );
      expect(
        AppException.mirrorUnavailable().userMessage,
        'The current source is unavailable. Please try again.',
      );
      expect(
        AppException.parsing().userMessage,
        'The article could not be processed.',
      );
      expect(
        AppException.storage().userMessage,
        'Could not save your data. Please try again.',
      );
      expect(
        AppException(type: AppErrorType.unknown, message: 'x').userMessage,
        'Something went wrong. Please try again.',
      );
    });

    test('custom userMessage overrides the default', () {
      final exception = AppException(
        type: AppErrorType.network,
        message: 'socket error',
        userMessage: 'No connection. Check your internet.',
      );

      expect(exception.message, 'socket error');
      expect(exception.userMessage, 'No connection. Check your internet.');
    });

    test('from wraps unknown errors as AppErrorType.unknown with cause', () {
      final error = StateError('boom');
      final exception = AppException.from(error, context: 'test');

      expect(exception.type, AppErrorType.unknown);
      expect(exception.cause, error);
      expect(exception.message, contains('test'));
    });

    test('from passes through existing AppException instances', () {
      final original = AppException.timeout();
      final wrapped = AppException.from(original);

      expect(identical(wrapped, original), isTrue);
    });

    test('toString includes type and message', () {
      final exception = AppException.invalidUrl('bad host');

      expect(exception.toString(), contains('invalidUrl'));
      expect(exception.toString(), contains('bad host'));
    });

    test('factory constructors capture the cause', () {
      final cause = UnsupportedError('x');
      final exception = AppException.network('wifi off', cause);

      expect(exception.cause, cause);
      expect(exception.type, AppErrorType.network);
    });
  });
}
