import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource_impl/call/matrix_rtc_media_keys.dart';

void main() {
  const alice = (userId: '@alice:hs', deviceId: 'A', createdTs: 1);
  const bob = (userId: '@bob:hs', deviceId: 'B', createdTs: 2);
  const bobAgain = (userId: '@bob:hs', deviceId: 'B', createdTs: 3);

  group('plan', () {
    test('a joiner gets the current key while it is recent', () {
      final plan = MatrixRtcMediaKeys.plan(
        sharedWith: {alice},
        members: {alice, bob},
        keyAge: const Duration(seconds: 3),
      );

      expect(plan.rotates, isFalse);
      expect(plan.recipients, {bob});
    });

    test('a joiner of an old key makes a new key for everyone', () {
      final plan = MatrixRtcMediaKeys.plan(
        sharedWith: {alice},
        members: {alice, bob},
        keyAge: const Duration(seconds: 30),
      );

      expect(plan.rotates, isTrue);
      expect(plan.recipients, {alice, bob});
    });

    test('a leaver makes a new key for those who stay', () {
      final plan = MatrixRtcMediaKeys.plan(
        sharedWith: {alice, bob},
        members: {alice},
        keyAge: const Duration(seconds: 1),
      );

      expect(plan.rotates, isTrue);
      expect(plan.recipients, {alice});
    });

    test('a device that joined again counts as a leaver and a joiner', () {
      final plan = MatrixRtcMediaKeys.plan(
        sharedWith: {alice, bob},
        members: {alice, bobAgain},
        keyAge: const Duration(seconds: 1),
      );

      expect(plan.rotates, isTrue);
      expect(plan.recipients, {alice, bobAgain});
    });

    test('nothing changed, nothing is sent', () {
      final plan = MatrixRtcMediaKeys.plan(
        sharedWith: {alice},
        members: {alice},
        keyAge: const Duration(minutes: 5),
      );

      expect(plan.recipients, isEmpty);
    });
  });

  group('parseKey', () {
    ToDeviceEvent keyEvent({
      Map<String, Object?>? content,
      bool isEncrypted = true,
    }) => ToDeviceEvent(
      sender: '@bob:hs',
      type: MatrixRtcMediaKeys.eventType,
      content:
          content ??
          {
            'keys': {'index': 2, 'key': 'AQID'},
            'room_id': '!room',
            'member': {'claimed_device_id': 'B', 'id': '@bob:hs:B'},
          },
      encryptedContent: isEncrypted ? {'algorithm': 'm.olm.v1'} : null,
    );

    test('reads the key of a device of the call', () {
      final key = MatrixRtcMediaKeys.parseKey(keyEvent(), '!room');

      expect(key?.participantId, '@bob:hs:B');
      expect(key?.index, 2);
      expect(key?.key, [1, 2, 3]);
    });

    test('ignores a key that came in the clear', () {
      expect(
        MatrixRtcMediaKeys.parseKey(keyEvent(isEncrypted: false), '!room'),
        isNull,
      );
    });

    test('ignores the key of another room', () {
      expect(MatrixRtcMediaKeys.parseKey(keyEvent(), '!other'), isNull);
    });

    test(
      'names the device from its claimed id when the member id is absent',
      () {
        final key = MatrixRtcMediaKeys.parseKey(
          keyEvent(
            content: {
              'keys': {'index': 0, 'key': 'AQ'},
              'room_id': '!room',
              'member': {'claimed_device_id': 'B'},
            },
          ),
          '!room',
        );

        expect(key?.participantId, '@bob:hs:B');
        expect(key?.key, [1]);
      },
    );
  });
}
