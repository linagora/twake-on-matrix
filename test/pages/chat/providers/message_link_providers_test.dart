import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/pages/chat/providers/message_link_providers.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

void main() {
  const roomId = '!abc:example.org';
  const eventId = r'$evt_1:example.org';
  final linkProvider = messageLinkProvider(roomId: roomId, eventId: eventId);

  ProviderContainer containerFor({String? userId}) => ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [activeUserIdProvider.overrideWithValue(userId)],
  );

  test('is a matrix.to permalink with the room server as via', () {
    expect(
      containerFor().read(linkProvider),
      'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org'
      '?via=example.org',
    );
  });

  test('adds the user server, then the room server, as via', () {
    expect(
      containerFor(userId: '@me:other.org').read(linkProvider),
      'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org'
      '?via=other.org&via=example.org',
    );
  });
}
