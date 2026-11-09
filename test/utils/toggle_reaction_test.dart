import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/utils/toggle_reaction.dart';

import 'toggle_reaction_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Event>()])
void main() {
  late List<String> calls;

  MockEvent reaction(String? key, {EventStatus status = EventStatus.synced}) {
    final event = MockEvent();
    when(event.status).thenReturn(status);
    when(event.content).thenReturn({
      'm.relates_to': {
        'rel_type': RelationshipTypes.reaction,
        'event_id': r'$message',
        'key': ?key,
      },
    });
    when(event.redactEvent()).thenAnswer((_) async {
      calls.add('redact ${key ?? 'no key'}');
      return r'$redaction';
    });
    return event;
  }

  Future<void> run({
    required String emoji,
    List<Event> mine = const [],
    bool sent = true,
  }) => toggleReaction(
    emoji: emoji,
    myReactions: mine,
    sendReaction: () async {
      calls.add('send $emoji');
      return sent;
    },
  );

  setUp(() => calls = []);

  test('sends when there is no existing reaction', () async {
    await run(emoji: '👍');
    expect(calls, ['send 👍']);
  });

  test('only redacts when the same emoji is selected', () async {
    await run(emoji: '👍', mine: [reaction('👍')]);
    expect(calls, ['redact 👍']);
  });

  test('sends then redacts when another emoji is selected', () async {
    await run(emoji: '😂', mine: [reaction('👍')]);
    expect(calls, ['send 😂', 'redact 👍']);
  });

  test('sends then redacts when existing reaction has no key', () async {
    await run(emoji: '😂', mine: [reaction(null)]);
    expect(calls, ['send 😂', 'redact no key']);
  });

  test(
    'only redacts when the selected emoji differs by a variation selector',
    () async {
      await run(emoji: '\u2764', mine: [reaction('\u2764\uFE0F')]);
      expect(calls, ['redact \u2764\uFE0F']);

      calls.clear();
      await run(emoji: '\u2764\uFE0F', mine: [reaction('\u2764')]);
      expect(calls, ['redact \u2764']);
    },
  );

  test(
    'only redacts when the selected emoji differs by a text variation selector',
    () async {
      await run(emoji: '\u2764', mine: [reaction('\u2764\uFE0E')]);
      expect(calls, ['redact \u2764\uFE0E']);

      calls.clear();
      await run(emoji: '\u2764\uFE0E', mine: [reaction('\u2764')]);
      expect(calls, ['redact \u2764']);
    },
  );

  test('waits for the replacement before redacting the old reaction', () async {
    final replacement = Completer<bool>();
    final change = toggleReaction(
      emoji: '😂',
      myReactions: [reaction('👍')],
      sendReaction: () {
        calls.add('send 😂');
        return replacement.future;
      },
    );
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['send 😂']);

    replacement.complete(true);
    await change;

    expect(calls, ['send 😂', 'redact 👍']);
  });

  test('keeps the old reaction when the replacement is not sent', () async {
    await run(emoji: '😂', mine: [reaction('👍')], sent: false);
    expect(calls, ['send 😂']);
  });

  test('keeps the old reaction when sending the replacement throws', () async {
    final change = toggleReaction(
      emoji: '😂',
      myReactions: [reaction('👍')],
      sendReaction: () async {
        calls.add('send 😂');
        throw Exception('send failed');
      },
    );

    await expectLater(change, throwsException);
    expect(calls, ['send 😂']);
  });

  test('reports a failed redaction after the replacement is sent', () async {
    final old = MockEvent();
    when(old.status).thenReturn(EventStatus.synced);
    when(old.content).thenReturn({
      'm.relates_to': {'key': '👍'},
    });
    when(old.redactEvent()).thenThrow(Exception('redact failed'));

    await expectLater(run(emoji: '😂', mine: [old]), throwsException);
    expect(calls, ['send 😂']);
  });

  test('removes a leftover reaction on the next change', () async {
    await run(emoji: '🎉', mine: [reaction('👍'), reaction('😂')]);
    expect(calls, ['send 🎉', 'redact 👍', 'redact 😂']);
  });

  test('ignores the tap while one of my reactions is still sending', () async {
    await run(
      emoji: '🎉',
      mine: [
        reaction('👍'),
        reaction('😂', status: EventStatus.sending),
      ],
    );
    expect(calls, isEmpty);
  });

  test('changes the reaction when my other one has a malformed key', () async {
    final malformed = MockEvent();
    when(malformed.status).thenReturn(EventStatus.synced);
    when(malformed.content).thenReturn({
      'm.relates_to': {'key': 42},
    });
    when(malformed.redactEvent()).thenAnswer((_) async {
      calls.add('redact malformed');
      return r'$redaction';
    });

    await run(emoji: '🎉', mine: [malformed, reaction('👍')]);
    expect(calls, ['send 🎉', 'redact malformed', 'redact 👍']);
  });

  test('never redacts a reaction whose send failed', () async {
    await run(
      emoji: '🎉',
      mine: [
        reaction('👍'),
        reaction('😂', status: EventStatus.error),
      ],
    );
    expect(calls, ['send 🎉', 'redact 👍']);
  });

  test('sends when my only reaction is one whose send failed', () async {
    await run(
      emoji: '🎉',
      mine: [reaction('😂', status: EventStatus.error)],
    );
    expect(calls, ['send 🎉']);
  });

  test('only removes the matching reaction when tapping one I hold', () async {
    await run(emoji: '😂', mine: [reaction('👍'), reaction('😂')]);
    expect(calls, ['redact 😂']);
  });
}
