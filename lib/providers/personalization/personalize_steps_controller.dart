import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';

part 'personalize_steps_controller.g.dart';

/// The ids of the personalization steps this device has seen, whatever the
/// width of the screen: what to ask comes from [pending] alone, once the
/// storage has answered, so a device that saw everything is never asked.
/// « Seen » stays on the device: the display choices are local too.
@Riverpod(keepAlive: true)
class PersonalizeStepsController extends _$PersonalizeStepsController {
  DisplayPreferencesRepository get _repository =>
      ref.read(displayPreferencesRepositoryProvider);

  @override
  Future<Set<String>> build() async {
    try {
      return await _repository.loadSeenSteps();
    } on Exception catch (exception, stackTrace) {
      Logs().w('PersonalizeStepsController::build', exception, stackTrace);
      return const {};
    }
  }

  /// The steps to ask on a screen of this width class: a phone ([isWide]
  /// false) is not asked the wide-only ones.
  Future<List<PersonalizeStep>> pending({required bool isWide}) async =>
      pendingSteps(await future, isWide: isWide);

  /// Remembers [shown] as seen, with what the device had seen before.
  Future<void> markSeen(Iterable<PersonalizeStep> shown) async {
    final seen = mergeSeenSteps(await future, shown).toSet();
    if (!ref.mounted) return;
    state = AsyncData(seen);
    try {
      await _repository.saveSeenSteps(seen);
    } on Exception catch (exception, stackTrace) {
      // Asked again at the next start: the user is never kept in the flow.
      Logs().w('PersonalizeStepsController::markSeen', exception, stackTrace);
    }
  }
}
