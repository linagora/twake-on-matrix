import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/usecases/get_room_access_usecase.provider.dart';
import 'package:twake_chat/domain/room_access/usecases/save_room_access_usecase.provider.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_state.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

part 'room_access_controller.g.dart';

/// Null when the section is not shown.
@riverpod
class RoomAccessController extends _$RoomAccessController {
  @override
  Future<RoomAccessState?> build(String roomId) async {
    final isEnabled = ref.watch(
      loginHomeserverSummaryProvider.select(
        (summary) => summary.isPublicGroupsEnabled,
      ),
    );
    if (!isEnabled) return null;
    final access = await ref
        .watch(getRoomAccessUseCaseProvider)
        .execute(roomId);
    if (!access.canChange) return null;
    return RoomAccessState.fromSaved(access);
  }

  void chooseJoinRule(JoinRuleChoice joinRule) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        joinRule: joinRule,
        isListed: joinRule == JoinRuleChoice.public || current.isListed,
      ),
    );
  }

  void setListed(bool isListed) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isListed: isListed));
  }

  /// Throws a `RoomAccessException` when the change is refused.
  Future<void> save() async {
    final current = state.value;
    if (current == null || !current.isDirty) return;
    await ref
        .read(saveRoomAccessUseCaseProvider)
        .execute(
          roomId,
          joinRule: current.changedJoinRule,
          isListed: current.changedIsListed,
        );
    if (!ref.mounted) return;
    state = AsyncData(
      current.copyWith(
        saved: current.saved.copyWith(
          joinRule: current.joinRule,
          isListed: current.isListed,
        ),
      ),
    );
  }
}
