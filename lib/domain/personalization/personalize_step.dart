import 'dart:convert';

/// A question of the personalization flow, in the order it is asked. [id] is
/// what the device stores once the step is seen: never change it. The id
/// `theme` is kept for a later step.
enum PersonalizeStep {
  density('density'),
  order('order'),
  seenStyle('seen-style'),
  composer('composer'),
  align('align');

  const PersonalizeStep(this.id);

  final String id;

  /// Asked on a wide screen only: a phone keeps its own message field.
  bool get isWideOnly => this == PersonalizeStep.composer;
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

/// The steps to ask: [unseenSteps], without the wide-only ones on a narrow
/// screen ([isWide] false).
List<PersonalizeStep> pendingSteps(
  Iterable<String> seen, {
  required bool isWide,
}) => [
  for (final step in unseenSteps(seen))
    if (isWide || !step.isWideOnly) step,
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
