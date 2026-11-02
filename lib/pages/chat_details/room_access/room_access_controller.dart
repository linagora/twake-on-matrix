import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/usecases/save_room_access_usecase.provider.dart';
import 'package:twake_chat/domain/room_access/usecases/watch_room_access_usecase.provider.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_draft.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

part 'room_access_controller.g.dart';

/// The saved access of the room; null when the section is not shown.
@riverpod
class RoomAccessController extends _$RoomAccessController {
  @override
  Stream<RoomAccess?> build(String roomId) {
    final isEnabled = ref.watch(
      loginHomeserverSummaryProvider.select(
        (summary) => summary.isPublicGroupsEnabled,
      ),
    );
    if (!isEnabled) return Stream.value(null);
    return ref
        .watch(watchRoomAccessUseCaseProvider)
        .execute(roomId)
        .map((access) => access.canChange ? access : null);
  }

  /// Throws a `RoomAccessException` when the change is refused.
  Future<void> save(RoomAccessDraft draft) async {
    final saved = state.value;
    if (saved == null || !draft.isDirtyOn(saved)) return;
    final joinRule = draft.changedJoinRuleOn(saved);
    final isListed = draft.changedIsListedOn(saved);
    await ref
        .read(saveRoomAccessUseCaseProvider)
        .execute(roomId, joinRule: joinRule, isListed: isListed);
    if (!ref.mounted) return;
    // The listing is not room state: no sync would report it.
    state = AsyncData(
      saved.copyWith(
        joinRule: joinRule ?? saved.joinRule,
        isListed: isListed ?? saved.isListed,
      ),
    );
  }
}
