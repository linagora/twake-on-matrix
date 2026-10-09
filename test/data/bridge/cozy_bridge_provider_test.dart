import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/bridge/cozy_bridge.dart';
import 'package:twake_chat/data/bridge/cozy_bridge.provider.dart';
import 'package:twake_chat/domain/model/drive/drive_exceptions.dart';

class _FakeDriveBridge implements CozyBridge {
  @override
  bool get isAvailable => true;

  @override
  Future<Object?> fetchJson({
    required CozyBridgeMethod method,
    required String path,
    required Map<String, dynamic> body,
  }) async => {'method': method.wireName, 'path': path};
}

void main() {
  group('cozyBridgeProvider', () {
    test('is unavailable outside the web container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final bridge = container.read(cozyBridgeProvider);

      expect(bridge.isAvailable, isFalse);
      expect(
        () => bridge.fetchJson(
          method: CozyBridgeMethod.post,
          path: '/intents',
          body: {},
        ),
        throwsA(isA<DriveBridgeUnavailableException>()),
      );
    });

    test('can be replaced by a fake', () async {
      final container = ProviderContainer(
        overrides: [cozyBridgeProvider.overrideWithValue(_FakeDriveBridge())],
      );
      addTearDown(container.dispose);

      final bridge = container.read(cozyBridgeProvider);

      expect(bridge.isAvailable, isTrue);
      expect(
        await bridge.fetchJson(
          method: CozyBridgeMethod.post,
          path: '/intents',
          body: {},
        ),
        {'method': 'POST', 'path': '/intents'},
      );
    });
  });
}
