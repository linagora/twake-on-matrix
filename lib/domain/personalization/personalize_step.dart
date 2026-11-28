import 'dart:convert';

/// A question of the personalization flow, in the order it is asked. [id] is
/// what the device stores once the step is seen: never change it. The id
/// `theme` is kept for a later step.
enum PersonalizeStep {
  density('density'),
  order('order'),
  searchBar('search-bar'),
  seenStyle('seen-style'),
  composer('composer'),
  align('align');

  const PersonalizeStep(this.id);

  final String id;

  /// Whether the step is asked on this width: the message field on a wide
  /// screen only (a phone keeps its own), the search bar on a phone only (a
  /// wide screen keeps its header search).
  bool isAskedOn({required bool isWide}) => switch (this) {
    PersonalizeStep.composer => isWide,
    PersonalizeStep.searchBar => !isWide,
    PersonalizeStep.density ||
    PersonalizeStep.order ||
    PersonalizeStep.seenStyle ||
    PersonalizeStep.align => true,
  };
}

/// The steps not in [seen], in order, whatever the width of the screen. Ids
/// this version does not know hide nothing.
List<PersonalizeStep> unseenSteps(Iterable<String> seen) {
  final seenIds = seen.toSet();
  return [
    for (final step in PersonalizeStep.values)
      if (!seenIds.contains(step.id)) step,
  ];
}

/// The steps to ask: [unseenSteps] that apply to this width ([isWide]).
List<PersonalizeStep> pendingSteps(
  Iterable<String> seen, {
  required bool isWide,
}) => [
  for (final step in unseenSteps(seen))
    if (step.isAskedOn(isWide: isWide)) step,
];

/// [seen] with the ids of [shown], each id once. The ids of a newer version
/// are kept.
List<String> mergeSeenSteps(
  Iterable<String> seen,
  Iterable<PersonalizeStep> shown,
) => {...seen, for (final step in shown) step.id}.toList();

/// The ids of a stored JSON list. Anything else reads as nothing seen.
List<String> parseSeenSteps(String? stored) {
  if (stored == null || stored.isEmpty) return const [];
  try {
    final decoded = jsonDecode(stored);
    return decoded is List ? decoded.whereType<String>().toList() : const [];
  } on FormatException {
    return const [];
  }
}
