import 'package:flutter/material.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/domain/personalization/chat_list_search_style.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';

/// One choice of a step: its stored name, its label, whether it is the
/// current one, and how to apply it.
typedef PersonalizeChoice = ({
  String name,
  String label,
  bool selected,
  VoidCallback onSelected,
});

/// The choices of each step, default first, read from the display
/// preferences.
class PersonalizeChoices {
  const PersonalizeChoices({
    required this.l10n,
    required this.preferences,
    required this.controller,
  });

  final L10n l10n;
  final DisplayPreferencesState preferences;
  final DisplayPreferencesController controller;

  /// The key of the control that selects [choice] of [step].
  static ValueKey<String> keyOf(PersonalizeStep step, String choice) =>
      ValueKey('option-${step.id}-$choice');

  List<PersonalizeChoice> of(PersonalizeStep step) => switch (step) {
    PersonalizeStep.density => [
      for (final density in ChatListDensity.values)
        _choice(
          density,
          preferences.density,
          controller.setDensity,
          switch (density) {
            ChatListDensity.comfortable => l10n.densityComfortable,
            ChatListDensity.compact => l10n.densityCompact,
          },
        ),
    ],
    PersonalizeStep.order => [
      for (final order in RoomOrder.values)
        _choice(
          order,
          preferences.roomOrder,
          controller.setRoomOrder,
          switch (order) {
            RoomOrder.recent => l10n.roomOrderRecent,
            RoomOrder.sections => l10n.roomOrderSections,
          },
        ),
    ],
    PersonalizeStep.searchBar => [
      for (final style in ChatListSearchStyle.values)
        _choice(
          style,
          preferences.searchStyle,
          controller.setSearchStyle,
          switch (style) {
            ChatListSearchStyle.bottomBar => l10n.searchBarBottom,
            ChatListSearchStyle.collapsing => l10n.searchBarCollapsing,
          },
        ),
    ],
    PersonalizeStep.seenStyle => [
      for (final style in SeenStyle.values)
        _choice(
          style,
          preferences.seenStyle,
          controller.setSeenStyle,
          switch (style) {
            SeenStyle.ticks => l10n.seenStyleTicks,
            SeenStyle.avatars => l10n.seenStyleAvatars,
            SeenStyle.names => l10n.seenStyleNames,
          },
        ),
    ],
    PersonalizeStep.composer => [
      for (final style in ComposerStyle.values)
        _choice(
          style,
          preferences.composerStyle,
          controller.setComposerStyle,
          switch (style) {
            ComposerStyle.compact => l10n.composerCompact,
            ComposerStyle.classic => l10n.composerClassic,
          },
        ),
    ],
    PersonalizeStep.align => [
      for (final align in BubbleAlign.values)
        _choice(
          align,
          preferences.bubbleAlign,
          controller.setBubbleAlign,
          switch (align) {
            BubbleAlign.ownRight => l10n.bubbleAlignOwnRight,
            BubbleAlign.left => l10n.bubbleAlignLeft,
          },
        ),
    ],
  };

  PersonalizeChoice _choice<T extends Enum>(
    T value,
    T current,
    ValueChanged<T> select,
    String label,
  ) => (
    name: value.name,
    label: label,
    selected: value == current,
    onSelected: () => select(value),
  );
}
