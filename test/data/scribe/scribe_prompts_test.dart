import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/scribe/scribe_prompts.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';

void main() {
  const prompts = ScribePrompts();

  test('sends the shared system text, then the task and the whole draft', () {
    final messages = prompts.messagesFor(
      ScribePrompt.translateEnglish,
      'Bonjour\nà tous',
    );

    expect(messages, hasLength(2));
    expect(messages[0]['role'], 'system');
    expect(
      messages[0]['content'],
      startsWith('You are a text editing assistant, NOT a chatbot.'),
    );
    expect(messages[1], {
      'role': 'user',
      'content':
          'INSTRUCTION:\nTranslate the text to English.\n\n'
          'TEXT:\nBonjour\nà tous\n',
    });
  });

  test('every option has its own task text', () {
    final tasks = ScribePrompt.values
        .map((prompt) => prompts.messagesFor(prompt, 'x')[1]['content'])
        .toSet();

    expect(tasks, hasLength(ScribePrompt.values.length));
  });
}
