import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/toggle_reaction.dart';

void main() {
  late List<String> calls;

  Future<void> run({required String emoji, String? key, bool hasMine = true}) =>
      toggleReaction(
        emoji: emoji,
        myReactionKey: key,
        redactMyReaction: hasMine ? () async => calls.add('redact') : null,
        sendReaction: () async => calls.add('send'),
      );

  setUp(() => calls = []);

  test('sends when there is no existing reaction', () async {
    await run(emoji: '👍', hasMine: false);
    expect(calls, ['send']);
  });

  test('only redacts when the same emoji is selected', () async {
    await run(emoji: '👍', key: '👍');
    expect(calls, ['redact']);
  });

  test('sends then redacts when another emoji is selected', () async {
    await run(emoji: '😂', key: '👍');
    expect(calls, ['send', 'redact']);
  });

  test('sends then redacts when existing reaction has no key', () async {
    await run(emoji: '😂');
    expect(calls, ['send', 'redact']);
  });

  test(
    'only redacts when the selected emoji differs by a variation selector',
    () async {
      await run(emoji: '\u2764', key: '\u2764\uFE0F');
      expect(calls, ['redact']);

      calls.clear();
      await run(emoji: '\u2764\uFE0F', key: '\u2764');
      expect(calls, ['redact']);
    },
  );

  test(
    'only redacts when the selected emoji differs by a text variation selector',
    () async {
      await run(emoji: '\u2764', key: '\u2764\uFE0E');
      expect(calls, ['redact']);

      calls.clear();
      await run(emoji: '\u2764\uFE0E', key: '\u2764');
      expect(calls, ['redact']);
    },
  );

  test('waits for the replacement before redacting the old reaction', () async {
    final replacement = Completer<void>();
    final change = toggleReaction(
      emoji: '\uD83D\uDE02',
      myReactionKey: '\uD83D\uDC4D',
      redactMyReaction: () async => calls.add('redact'),
      sendReaction: () {
        calls.add('send');
        return replacement.future;
      },
    );
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['send']);

    replacement.complete();
    await change;

    expect(calls, ['send', 'redact']);
  });

  test('keeps the old reaction when sending the replacement fails', () async {
    final change = toggleReaction(
      emoji: '\uD83D\uDE02',
      myReactionKey: '\uD83D\uDC4D',
      redactMyReaction: () async => calls.add('redact'),
      sendReaction: () async {
        calls.add('send');
        throw Exception('send failed');
      },
    );

    await expectLater(change, throwsException);
    expect(calls, ['send']);
  });
}
