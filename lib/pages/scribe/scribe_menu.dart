import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';

enum ScribeMenu {
  root,
  improve,
  tone,
  translate;

  List<ScribeMenuEntry> get entries => switch (this) {
    ScribeMenu.root => const [
      ScribePromptEntry(ScribePrompt.correctGrammar),
      ScribeSubmenuEntry(ScribeMenu.improve),
      ScribeSubmenuEntry(ScribeMenu.tone),
      ScribeSubmenuEntry(ScribeMenu.translate),
      ScribePromptEntry(ScribePrompt.summarize),
    ],
    ScribeMenu.improve => const [
      ScribePromptEntry(ScribePrompt.makeShorter),
      ScribePromptEntry(ScribePrompt.expandContext),
      ScribePromptEntry(ScribePrompt.emojify),
      ScribePromptEntry(ScribePrompt.transformToBullets),
    ],
    ScribeMenu.tone => const [
      ScribePromptEntry(ScribePrompt.changeToneProfessional),
      ScribePromptEntry(ScribePrompt.changeToneCasual),
      ScribePromptEntry(ScribePrompt.changeTonePolite),
    ],
    ScribeMenu.translate => const [
      ScribePromptEntry(ScribePrompt.translateFrench),
      ScribePromptEntry(ScribePrompt.translateEnglish),
      ScribePromptEntry(ScribePrompt.translateRussian),
      ScribePromptEntry(ScribePrompt.translateVietnamese),
    ],
  };
}

sealed class ScribeMenuEntry {
  const ScribeMenuEntry();
}

final class ScribePromptEntry extends ScribeMenuEntry {
  const ScribePromptEntry(this.prompt);

  final ScribePrompt prompt;
}

final class ScribeSubmenuEntry extends ScribeMenuEntry {
  const ScribeSubmenuEntry(this.menu);

  final ScribeMenu menu;
}
