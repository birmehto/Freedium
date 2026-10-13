import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/services/ad_failure.dart';
import 'package:freedium/core/services/ad_service.dart';

void main() {
  AdFailureReason classify(
    int code, {
    bool android = true,
    String message = '',
  }) {
    return classifyAdFailure(code: code, message: message, isAndroid: android);
  }

  group('classifyAdFailure by Android code', () {
    test('network error is a connection problem', () {
      expect(classify(2), AdFailureReason.noConnection);
    });

    test('no fill and mediation no-fill mean no inventory', () {
      expect(classify(3), AdFailureReason.noFill);
      expect(classify(9), AdFailureReason.noFill);
    });

    test('invalid request, app ID, request ID and ad string are misconfig', () {
      expect(classify(1), AdFailureReason.invalidRequest);
      expect(classify(8), AdFailureReason.invalidRequest);
      expect(classify(10), AdFailureReason.invalidRequest);
      expect(classify(11), AdFailureReason.invalidRequest);
    });

    test('internal error is a server problem', () {
      expect(classify(0), AdFailureReason.serverError);
    });
  });

  group('classifyAdFailure by iOS code', () {
    test('no fill is 1 on iOS, not 3', () {
      expect(classify(1, android: false), AdFailureReason.noFill);
    });

    test('invalid request is 0 on iOS and app ID is 20', () {
      expect(classify(0, android: false), AdFailureReason.invalidRequest);
      expect(classify(20, android: false), AdFailureReason.invalidRequest);
    });

    test('server and internal errors are server problems', () {
      expect(classify(3, android: false), AdFailureReason.serverError);
      expect(classify(11, android: false), AdFailureReason.serverError);
    });

    test('network error is 2, same as Android', () {
      expect(classify(2, android: false), AdFailureReason.noConnection);
    });

    test('timeout has a dedicated code', () {
      expect(classify(5, android: false), AdFailureReason.timeout);
    });
  });

  group('classifyAdFailure by message', () {
    test('a blocked ad host is a connection problem', () {
      expect(
        classify(
          0,
          message:
              'Error while connecting to ad server: Failed to connect to '
              'googleads.g.doubleclick.net/[::]:443',
        ),
        AdFailureReason.noConnection,
      );
    });

    test('a DNS failure is a connection problem', () {
      expect(
        classify(
          0,
          message: 'Unable to resolve host "googleads.g.doubleclick.net"',
        ),
        AdFailureReason.noConnection,
      );
    });

    test('a timeout message is a timeout', () {
      expect(
        classify(0, message: 'The request timed out.'),
        AdFailureReason.timeout,
      );
    });

    test('an unknown error stays unknown', () {
      expect(
        classify(99, message: 'Something completely unexpected'),
        AdFailureReason.unknown,
      );
    });
  });
}
