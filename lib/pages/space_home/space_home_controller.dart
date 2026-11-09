import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/domain/spaces/usecases/get_space_usecase.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/open_space_usecase.provider.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:twake_chat/providers/room_list/room_list_entries_provider.dart';

part 'space_home_controller.freezed.dart';
part 'space_home_controller.g.dart';

@freezed
abstract class SpaceHomeState with _$SpaceHomeState {
  const factory SpaceHomeState({
    /// `null` for anything but a joined space.
    SpaceSummary? space,
  }) = _SpaceHomeState;
}

/// Read at once: a room opens as a conversation without waiting.
@riverpod
class SpaceHomeController extends _$SpaceHomeController {
  @override
  SpaceHomeState build(String roomId) {
    ref.watch(roomChangesProvider);
    return SpaceHomeState(
      space: ref.watch(getSpaceUseCaseProvider).execute(roomId),
    );
  }

  /// What opening the home does: reads the whole space, marks it read and asks
  /// what it holds now.
  Future<void> open() async {
    await ref.read(openSpaceUseCaseProvider).execute(roomId);
    if (!ref.mounted) return;
    ref.invalidate(spaceChildrenProvider(roomId));
    ref.invalidateSelf();
  }
}
