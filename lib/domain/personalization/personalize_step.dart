/// A question of the personalization choices, in the order it is asked. [id]
/// is what the device stores once the step is seen: never change it.
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
