import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';

/// A page of the Scribe menu. A submenu replaces the root, as in the mobile
/// design; its header goes back to the root.
enum ScribeMenu {
  root,
  improve,
  tone,
  translate;

  /// The entries in the order of Chat web's menu.
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

/// One line of a Scribe menu.
sealed class ScribeMenuEntry {
  const ScribeMenuEntry();
}

/// Runs [prompt] on the draft.
final class ScribePromptEntry extends ScribeMenuEntry {
  const ScribePromptEntry(this.prompt);

  final ScribePrompt prompt;
}

/// Opens [menu] in place of the current page.
final class ScribeSubmenuEntry extends ScribeMenuEntry {
  const ScribeSubmenuEntry(this.menu);

  final ScribeMenu menu;
}
