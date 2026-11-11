import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';

import '../../../fake_client.dart';

void main() {
  late Room room;

  setUpAll(() async {
    room = Room(
      client: await getClient(),
      id: '!test:example.com',
      membership: Membership.join,
    );
  });

  String? hrefOf(String message) {
    final content = room.getEventContentFromMsgText(message: message);
    final html = content['formatted_body'] as String?;
    if (html == null) return null;
    return RegExp(r'href="([^"]*)"').firstMatch(html)?.group(1);
  }

  // The link Copy link puts on the clipboard: room and event ids encoded
  // once, as matrix.to and the web app do.
  const messageLink =
      'https://matrix.to/#/!cqaj%3Astg.example.org/%24M4A2_abc-def';

  test('a pasted message link keeps its encoding in the sent HTML', () {
    expect(hrefOf(messageLink), messageLink);
  });

  test('a message link inside text keeps its encoding in the sent HTML', () {
    expect(hrefOf('see $messageLink please'), messageLink);
  });

  test('a markdown link written with %25 keeps it, as CommonMark says', () {
    expect(
      hrefOf('[label](https://example.org/a%253Ab)'),
      'https://example.org/a%253Ab',
    );
  });
}
