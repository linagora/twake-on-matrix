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

  test('redacts then sends when another emoji is selected', () async {
    await run(emoji: '😂', key: '👍');
    expect(calls, ['redact', 'send']);
  });

  test('redacts then sends when existing reaction has no key', () async {
    await run(emoji: '😂');
    expect(calls, ['redact', 'send']);
  });
}
