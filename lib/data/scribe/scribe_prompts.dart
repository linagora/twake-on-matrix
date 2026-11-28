import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';

class ScribePrompts {
  const ScribePrompts();

  List<Map<String, String>> messagesFor(ScribePrompt prompt, String text) => [
    {'role': 'system', 'content': _system},
    {
      'role': 'user',
      'content': 'INSTRUCTION:\n${_taskOf(prompt)}\n\nTEXT:\n$text\n',
    },
  ];

  String _taskOf(ScribePrompt prompt) => switch (prompt) {
    ScribePrompt.correctGrammar => _correctGrammar,
    ScribePrompt.makeShorter =>
      'Make the text shorter while preserving its meaning.',
    ScribePrompt.expandContext =>
      'Expand the context of the text to make it more detailed and '
          'comprehensive.',
    ScribePrompt.emojify =>
      'Add emojis to the important parts of the text. Do not try to rephrase '
          'or replace text.',
    ScribePrompt.transformToBullets =>
      'Convert the following text into structured bulleted lists, clearly '
          'separating distinct use cases.',
    ScribePrompt.changeToneProfessional =>
      'Change the tone to be professional.',
    ScribePrompt.changeToneCasual => 'Change the tone to be casual.',
    ScribePrompt.changeTonePolite => 'Change the tone to be polite.',
    ScribePrompt.translateFrench => 'Translate the text to French.',
    ScribePrompt.translateEnglish => 'Translate the text to English.',
    ScribePrompt.translateRussian => 'Translate the text to Russian.',
    ScribePrompt.translateVietnamese => 'Translate the text to Vietnamese.',
    ScribePrompt.summarize => _summarize,
  };

  static const _system = '''
You are a text editing assistant, NOT a chatbot.
Your task is to apply EXACTLY the editing instruction given by the user to the provided text. You must behave as a deterministic text transformation tool.

CRITICAL RULES (must be followed strictly):
1. Output ONLY the edited text. No explanations, no comments.
2. Do NOT repeat the instruction.
3. Do NOT add any new content beyond what is required by the instruction. Never say things like "Here is the result" or "Sure". Just answer the instruction.
4. PRESERVE the original language of the input text. For example, if it's French, keep French. If it's English, keep English. ONLY change the language if the instruction EXPLICITLY asks for a translation to another language.''';

  static const _correctGrammar = '''
Correct the grammar and spelling of the text.

Change only what is wrong:
- Fix the misspelled words, the agreements, the conjugations and the punctuation
- Keep every word that is right: do not replace a word with a synonym, and do not rephrase
- Keep the lines and the paragraphs of the text''';

  static const _summarize = '''
Summarize the text from the user.

Your goal:
- Produce a clear and accurate summary of the provided content
- Keep the original meaning and key information only
- Remove redundancy, examples, anecdotes, and minor details

Output:
- A single coherent paragraph unless otherwise specified, even for a list or several paragraphs
- Short: one to three sentences that name the main ideas in a few words each, and leave out their details
- Keep any request made to the reader, with its deadline
- Always much shorter than the text, even when the text is already short
- Do not add any extra information or interpret anything beyond the explicit task''';
}
