import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/usecases/set_scribe_enabled_usecase.provider.dart';
import 'package:twake_chat/pages/scribe/providers/scribe_room_provider.dart';

part 'scribe_setting_controller.g.dart';

/// The value an owner asked for, while the switch waits for it.
typedef ScribeSettingWanted = ({bool enabled, bool saving});

/// The owner's Scribe switch of one room. The state is the value asked for,
/// shown until the room comes back with the sync; null when the switch shows
/// the room's own state.
@riverpod
class ScribeSettingController extends _$ScribeSettingController {
  @override
  ScribeSettingWanted? build(String roomId) {
    ref.listen<ScribeRoom?>(
      scribeRoomProvider(roomId).select((room) => room.value),
      (_, room) {
        final wanted = state;
        if (room == null || wanted == null) return;
        // Once the write is done, the room's next state wins, even when
        // another owner flipped it back meanwhile.
        if (room.scribeEnabled == wanted.enabled || !wanted.saving) {
          state = null;
        }
      },
    );
    return null;
  }

  /// Throws the `ScribeException`s of `SetScribeEnabledUseCase.execute`; the
  /// switch then shows the room's state again.
  Future<void> save(ScribeRoom room, {required bool enabled}) async {
    state = (enabled: enabled, saving: true);
    try {
      await ref
          .read(setScribeEnabledUseCaseProvider)
          .execute(roomId: roomId, room: room, enabled: enabled);
      // The sync may already have brought the value back.
      if (ref.mounted && state != null) {
        state = (enabled: enabled, saving: false);
      }
    } on Exception {
      if (ref.mounted) state = null;
      rethrow;
    }
  }
}
