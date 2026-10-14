import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/sentry_init.dart';

void main() {
  group('isLocalBuild', () {
    test('debug builds are local', () {
      expect(isLocalBuild(isDebug: true, webHost: null), isTrue);
      expect(isLocalBuild(isDebug: true, webHost: 'chat.twake.app'), isTrue);
    });

    test('release mobile builds are not local', () {
      expect(isLocalBuild(isDebug: false, webHost: null), isFalse);
    });

    for (final host in ['localhost', '127.0.0.1', '::1', 'chat.localhost']) {
      test('release web served from $host is local', () {
        expect(isLocalBuild(isDebug: false, webHost: host), isTrue);
      });
    }

    test('release web served from a real domain is not local', () {
      expect(isLocalBuild(isDebug: false, webHost: 'chat.twake.app'), isFalse);
    });
  });
}
