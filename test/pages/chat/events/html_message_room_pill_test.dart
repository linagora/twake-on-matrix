// Issue #2135: a mention of a room shows the room's name, not its raw id.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/html_message.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/mentioned_user.dart';

import '../../../fake_client.dart';

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

const _targetId = '!standups:example.org';
const _targetAlias = '#standups:example.org';
const _targetName = 'everyday stand ups';

Room _namedRoom(Client client) {
  final target = Room(id: _targetId, client: client);
  target.setState(
    StrippedStateEvent(
      type: EventTypes.RoomName,
      content: {'name': _targetName},
      senderId: '@admin:example.org',
      stateKey: '',
    ),
  );
  target.setState(
    StrippedStateEvent(
      type: EventTypes.RoomCanonicalAlias,
      content: {'alias': _targetAlias},
      senderId: '@admin:example.org',
      stateKey: '',
    ),
  );
  return target;
}

Future<void> _pump(WidgetTester tester, Room room, String html) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Provider<MatrixState>.value(
          value: _FakeMatrixState(room.client),
          child: Scaffold(
            body: HtmlMessage(
              html: html,
              room: room,
              linkStyle: const TextStyle(color: Colors.blue),
            ),
          ),
        ),
      ),
    );

List<String> _mentions(WidgetTester tester) => tester
    .widgetList<MentionedUser>(find.byType(MentionedUser))
    .map((mention) => mention.displayName)
    .toList();

void main() {
  late Room room;

  setUpAll(() async {
    final client = await getClient();
    client.rooms.add(_namedRoom(client));
    room = Room(id: '!group:example.org', client: client);
  });

  group('HtmlMessage room pills', () {
    testWidgets('shows the name of a room mentioned by id', (tester) async {
      await _pump(
        tester,
        room,
        '<p>also in <a href="https://matrix.to/#/$_targetId">$_targetId</a></p>',
      );

      expect(_mentions(tester), [_targetName]);
    });

    testWidgets('shows the name of a room mentioned by alias', (tester) async {
      await _pump(
        tester,
        room,
        '<p>also in <a href="https://matrix.to/#/$_targetAlias">$_targetAlias</a></p>',
      );

      expect(_mentions(tester), [_targetName]);
    });

    testWidgets('keeps the raw id of a room the user is not in', (
      tester,
    ) async {
      const unknown = '!unknown:example.org';
      await _pump(
        tester,
        room,
        '<p><a href="https://matrix.to/#/$unknown">$unknown</a></p>',
      );

      expect(_mentions(tester), ['@[$unknown]']);
    });

    testWidgets('keeps the mention form of a user pill', (tester) async {
      const alice = '@alice:example.org';
      await _pump(
        tester,
        room,
        '<p>hi <a href="https://matrix.to/#/$alice">Alice</a></p>',
      );

      expect(_mentions(tester), ['@[$alice]']);
    });
  });
}
