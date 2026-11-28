import 'package:freezed_annotation/freezed_annotation.dart';

part 'personalize_steps_state.freezed.dart';

/// The personalization steps this device has seen, by id: the ids of a newer
/// version are kept.
@freezed
abstract class PersonalizeStepsState with _$PersonalizeStepsState {
  const factory PersonalizeStepsState({@Default({}) Set<String> seen}) =
      _PersonalizeStepsState;
}
