import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/desktop_lifecycle.dart';

class _FakePort implements DesktopLifecyclePort {
  final calls = <bool>[];
  Object? failure;

  @override
  Future<void> setKeepRunningWhenWindowClosed(bool keepRunning) async {
    final f = failure;
    if (f != null) throw f;
    calls.add(keepRunning);
  }
}

void main() {
  group('shouldKeepRunningAfterLastWindowClosed', () {
    test('macOS with a signed-in account keeps the app alive (sync and '
        'notifications continue)', () {
      expect(
        shouldKeepRunningAfterLastWindowClosed(isMacOS: true, isLoggedIn: true),
        isTrue,
      );
    });

    test('macOS without an account quits: nothing to sync', () {
      expect(
        shouldKeepRunningAfterLastWindowClosed(
          isMacOS: true,
          isLoggedIn: false,
        ),
        isFalse,
      );
    });

    test('other platforms keep their usual behaviour (quit)', () {
      expect(
        shouldKeepRunningAfterLastWindowClosed(
          isMacOS: false,
          isLoggedIn: true,
        ),
        isFalse,
      );
    });
  });

  group('DesktopLifecycle', () {
    test(
      'tells the native side to keep running once the user is signed in',
      () async {
        final port = _FakePort();
        final lifecycle = DesktopLifecycle(port, isMacOS: true);

        await lifecycle.onLoginStateChanged(isLoggedIn: true);

        expect(port.calls, [true]);
      },
    );

    test('tells the native side to quit on close after logout', () async {
      final port = _FakePort();
      final lifecycle = DesktopLifecycle(port, isMacOS: true);
      await lifecycle.onLoginStateChanged(isLoggedIn: true);

      await lifecycle.onLoginStateChanged(isLoggedIn: false);

      expect(port.calls, [true, false]);
    });

    test('does not repeat the same value', () async {
      final port = _FakePort();
      final lifecycle = DesktopLifecycle(port, isMacOS: true);

      await lifecycle.onLoginStateChanged(isLoggedIn: true);
      await lifecycle.onLoginStateChanged(isLoggedIn: true);

      expect(port.calls, [true]);
    });

    test('does nothing on other platforms', () async {
      final port = _FakePort();
      final lifecycle = DesktopLifecycle(port, isMacOS: false);

      await lifecycle.onLoginStateChanged(isLoggedIn: true);

      expect(port.calls, isEmpty);
    });

    test('a native failure never throws into the app', () async {
      final port = _FakePort()..failure = Exception('channel missing');
      final lifecycle = DesktopLifecycle(port, isMacOS: true);

      await expectLater(
        lifecycle.onLoginStateChanged(isLoggedIn: true),
        completes,
      );
    });
  });
}
