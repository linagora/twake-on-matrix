import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/usecases/set_scribe_enabled_usecase.provider.dart';
import 'package:twake_chat/pages/scribe/providers/scribe_room_provider.dart';

part 'scribe_setting_controller.g.dart';

typedef ScribeSettingWanted = ({bool enabled, bool saving});

@riverpod
class ScribeSettingController extends _$ScribeSettingController {
  @override
  ScribeSettingWanted? build(String roomId) {
    ref.listen<ScribeRoom?>(
      scribeRoomProvider(roomId).select((room) => room.value),
      (_, room) {
        final wanted = state;
        if (room == null || wanted == null) return;
        if (room.scribeEnabled == wanted.enabled || !wanted.saving) {
          state = null;
        }
      },
    );
    return null;
  }

  Future<void> save(ScribeRoom room, {required bool enabled}) async {
    state = (enabled: enabled, saving: true);
    try {
      await ref
          .read(setScribeEnabledUseCaseProvider)
          .execute(roomId: roomId, room: room, enabled: enabled);
      if (ref.mounted && state != null) {
        state = (enabled: enabled, saving: false);
      }
    } on Exception {
      if (ref.mounted) state = null;
      rethrow;
    }
  }
}
