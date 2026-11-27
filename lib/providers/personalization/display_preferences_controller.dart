import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';

part 'display_preferences_controller.g.dart';

typedef _Change =
    DisplayPreferencesState Function(DisplayPreferencesState preferences);

/// The display choices of this device, kept by [DisplayPreferencesRepository].
/// A choice shows at once and is saved; one made before the storage has
/// answered is applied once it has, so it wins over what it held.
@Riverpod(keepAlive: true)
class DisplayPreferencesController extends _$DisplayPreferencesController {
  DisplayPreferencesRepository get _repository =>
      ref.read(displayPreferencesRepositoryProvider);

  @override
  Future<DisplayPreferencesState> build() async {
    try {
      return await _repository.load();
    } on Exception catch (exception, stackTrace) {
      Logs().w('DisplayPreferencesController::build', exception, stackTrace);
      return const DisplayPreferencesState();
    }
  }

  void _choose(_Change change) {
    final current = state.value;
    if (current == null) {
      unawaited(future.then((_) => _choose(change)));
      return;
    }
    final next = change(current);
    state = AsyncData(next);
    unawaited(_save(next));
  }

  Future<void> _save(DisplayPreferencesState next) async {
    try {
      await _repository.save(next);
    } on Exception catch (exception, stackTrace) {
      // The choice holds until the next start.
      Logs().w('DisplayPreferencesController::_save', exception, stackTrace);
    }
  }

  void setDensity(ChatListDensity density) =>
      _choose((p) => p.copyWith(density: density));

  void setRoomOrder(RoomOrder order) =>
      _choose((p) => p.copyWith(roomOrder: order));
}

/// The choices as they are now: the defaults until the storage has answered.
@Riverpod(keepAlive: true)
DisplayPreferencesState displayPreferences(Ref ref) =>
    ref.watch(displayPreferencesControllerProvider).value ??
    const DisplayPreferencesState();
