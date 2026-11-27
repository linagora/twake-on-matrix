part of 'personalize_drawings.dart';

/// The choices of one personalization step as cards (Settings ›
/// Personalization), each with a drawn preview. A tap applies the choice at
/// once. The card of a choice is keyed `option-<step id>-<choice>`.
class PersonalizeStepCards extends ConsumerWidget {
  const PersonalizeStepCards({super.key, required this.step});

  final PersonalizeStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(displayPreferencesProvider);
    final choices = PersonalizeChoices(
      l10n: L10n.of(context)!,
      preferences: preferences,
      controller: ref.read(displayPreferencesControllerProvider.notifier),
    ).of(step);
    return OptionCards<PersonalizeChoice>(
      value: choices.firstWhere((choice) => choice.selected),
      layout: switch (step) {
        PersonalizeStep.density ||
        PersonalizeStep.order => OptionCardsLayout.sideBySide,
        PersonalizeStep.seenStyle => OptionCardsLayout.stacked,
        PersonalizeStep.composer => OptionCardsLayout.stacked,
        PersonalizeStep.align => OptionCardsLayout.stacked,
      },
      onChanged: (choice) => choice.onSelected(),
      choices: [
        for (final choice in choices)
          OptionCardChoice<PersonalizeChoice>(
            key: PersonalizeChoices.keyOf(step, choice.name),
            value: choice,
            label: choice.label,
            preview: _preview(choice.name, preferences),
          ),
      ],
    );
  }

  Widget _preview(String name, DisplayPreferencesState preferences) =>
      switch (step) {
        PersonalizeStep.density => _MiniRoomList(
          compact: name == ChatListDensity.compact.name,
          sections: preferences.roomOrder == RoomOrder.sections,
        ),
        PersonalizeStep.order => _MiniRoomList(
          compact: preferences.density == ChatListDensity.compact,
          sections: name == RoomOrder.sections.name,
        ),
        PersonalizeStep.seenStyle => _MiniSeen(
          style: SeenStyle.values.byName(name),
        ),
        PersonalizeStep.composer => _MiniComposer(
          style: ComposerStyle.values.byName(name),
        ),
        PersonalizeStep.align => _MiniBubbles(
          ownRight: name == BubbleAlign.ownRight.name,
        ),
      };
}
