import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/background_push.dart';

import '../fake_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Client first;
  late Client second;
  late Client third;
  late BackgroundPush push;

  setUp(() async {
    first = await getClient();
    second = await getClient();
    third = await getClient();
    // The service is a singleton: each test starts from a known client.
    push = BackgroundPush.clientOnly(first)..rebind(first);
  });

  group('rebindFrom', () {
    test('the account served goes away: the replacement is served', () {
      expect(push.rebindFrom(first, second), isTrue);

      expect(push.client, same(second));
      expect(push.isSetUp, isFalse);
    });

    test('another account goes away: the service keeps its client', () {
      expect(push.rebindFrom(third, second), isFalse);

      expect(push.client, same(first));
    });

    test('the replacement is the departed account: nothing changes', () {
      expect(push.rebindFrom(first, first), isFalse);

      expect(push.client, same(first));
    });
  });

  group('UnifiedPush guard', () {
    test('a rebind lets the next account be set up again', () {
      push.upAction = true;

      push.rebind(second);

      expect(push.upAction, isFalse);
    });

    test('forgetting the setup lets the next login set up again', () {
      push.upAction = true;

      push.forgetSetup();

      expect(push.upAction, isFalse);
    });
  });

  group('pushKeys', () {
    setUp(() => push.useUpEndpoint(null));

    test('a UnifiedPush endpoint is a key of the device', () {
      expect(push.hasPushToken, isFalse);

      push.useUpEndpoint('https://up.example/endpoint');

      expect(push.pushKeys, contains('https://up.example/endpoint'));
      expect(push.hasPushToken, isTrue);
    });

    test('an endpoint that is gone is no key', () {
      push.useUpEndpoint('https://up.example/endpoint');

      push.useUpEndpoint(null);

      expect(push.pushKeys, isEmpty);
      expect(push.hasPushToken, isFalse);
    });
  });
}
