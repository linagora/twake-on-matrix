/// An option of the Scribe menu, by its prompt of the shared catalogue
/// `linagora/ai-prompts` (named in the comment of each value).
enum ScribePrompt {
  /// `correct-grammar`, the Correct entry.
  correctGrammar,

  /// `make-shorter`, under Improve.
  makeShorter,

  /// `expand-context`, under Improve.
  expandContext,

  /// `emojify`, under Improve.
  emojify,

  /// `transform-to-bullets`, under Improve.
  transformToBullets,

  /// `change-tone-professional`, under Tone.
  changeToneProfessional,

  /// `change-tone-casual`, under Tone.
  changeToneCasual,

  /// `change-tone-polite`, under Tone.
  changeTonePolite,

  /// `translate-french`, under Translate.
  translateFrench,

  /// `translate-english`, under Translate.
  translateEnglish,

  /// `translate-russian`, under Translate.
  translateRussian,

  /// `translate-vietnamese`, under Translate.
  translateVietnamese,

  /// `summarize`, the Summarize entry.
  summarize,
}
