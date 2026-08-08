import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:localink_mobile/core/network/app_error_formatter.dart';
import 'package:localink_mobile/core/network/dio_auth_policy.dart';

void main() {
  group('DioAuthPolicy', () {
    test('auth bootstrap paths do not refresh', () {
      expect(DioAuthPolicy.isAuthBootstrapPath('auth/sessions'), isTrue);
      expect(DioAuthPolicy.isAuthBootstrapPath('/api/v1/auth/refresh'), isTrue);
      expect(DioAuthPolicy.isAuthBootstrapPath('auth/logout'), isTrue);
      expect(DioAuthPolicy.isAuthBootstrapPath('auth/register'), isTrue);
      expect(DioAuthPolicy.isAuthBootstrapPath('auth/google'), isTrue);
      expect(DioAuthPolicy.isAuthBootstrapPath('business/my-businesses'), isFalse);
    });

    test('shouldAttemptRefresh only on non-bootstrap 401', () {
      expect(
        DioAuthPolicy.shouldAttemptRefresh(
          statusCode: 401,
          path: 'favorites/user/1',
        ),
        isTrue,
      );
      expect(
        DioAuthPolicy.shouldAttemptRefresh(
          statusCode: 401,
          path: 'auth/sessions',
        ),
        isFalse,
      );
      expect(
        DioAuthPolicy.shouldAttemptRefresh(
          statusCode: 403,
          path: 'favorites/user/1',
        ),
        isFalse,
      );
    });
  });

  group('AppErrorFormatter', () {
    test('formats connection errors as offline', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );
      expect(AppErrorFormatter.isOfflineError(err), isTrue);
      expect(
        AppErrorFormatter.format(err),
        contains('No internet connection'),
      );
    });

    test('formats 401 response message', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 401,
        ),
      );
      expect(AppErrorFormatter.format(err), contains('Invalid credentials'));
    });

    test('strips Exception: prefix', () {
      expect(AppErrorFormatter.format(Exception('boom')), 'boom');
    });
  });
}
