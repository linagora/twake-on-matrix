import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.provider.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/domain/personalization/personalize_steps_state.dart';

part 'personalize_steps_controller.g.dart';

/// The personalization steps this device has seen, whatever the
/// width of the screen: what to ask comes from [pending] alone, once the
/// storage has answered, so a device that saw everything is never asked.
/// « Seen » stays on the device: the display choices are local too.
@Riverpod(keepAlive: true)
class PersonalizeStepsController extends _$PersonalizeStepsController {
  DisplayPreferencesRepository get _repository =>
      ref.read(displayPreferencesRepositoryProvider);

  // True while the device's seen steps could not be read: saving would
  // replace them with what this run alone has seen.
  bool _loadFailed = false;

  @override
  Future<PersonalizeStepsState> build() async {
    try {
      _loadFailed = false;
      return PersonalizeStepsState(seen: await _repository.loadSeenSteps());
    } on Exception catch (exception, stackTrace) {
      Logs().w('PersonalizeStepsController::build', exception, stackTrace);
      _loadFailed = true;
      return const PersonalizeStepsState();
    }
  }

  /// The steps to ask on a screen of this width class: a phone ([isWide]
  /// false) is not asked the wide-only ones.
  Future<List<PersonalizeStep>> pending({required bool isWide}) async =>
      pendingSteps((await future).seen, isWide: isWide);

  /// Remembers [shown] as seen, with what the device had seen before.
  Future<void> markSeen(Iterable<PersonalizeStep> shown) async {
    await future;
    await _retryFailedLoad();
    if (!ref.mounted) return;
    // No await between reading the state and assigning it: two calls at the
    // same time each keep the steps of the other.
    final next = PersonalizeStepsState(
      seen: mergeSeenSteps(state.requireValue.seen, shown).toSet(),
    );
    // Nothing new: the state stays equal and nobody is told.
    if (state.value != next) state = AsyncData(next);
    // Still unread: the device keeps what it stored, asked again next start.
    if (_loadFailed) return;
    await _save(next);
  }

  Future<void> _retryFailedLoad() async {
    if (!_loadFailed) return;
    try {
      final stored = await _repository.loadSeenSteps();
      if (!ref.mounted) return;
      _loadFailed = false;
      state = AsyncData(
        PersonalizeStepsState(seen: {...state.requireValue.seen, ...stored}),
      );
    } on Exception catch (exception, stackTrace) {
      Logs().w('PersonalizeStepsController::retry', exception, stackTrace);
    }
  }

  Future<void> _save(PersonalizeStepsState next) async {
    try {
      await _repository.saveSeenSteps(next.seen);
    } on Exception catch (exception, stackTrace) {
      // Asked again at the next start: the user is never kept in the flow.
      Logs().w('PersonalizeStepsController::markSeen', exception, stackTrace);
    }
  }
}
