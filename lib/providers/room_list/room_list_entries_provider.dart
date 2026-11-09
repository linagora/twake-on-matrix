import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/usecases/get_room_list_entries_usecase.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/watch_room_changes_usecase.provider.dart';

part 'room_list_entries_provider.g.dart';

/// Ticks when the rooms of the active account change.
@riverpod
Stream<int> roomChanges(Ref ref) =>
    ref.watch(watchRoomChangesUseCaseProvider).execute();

/// The rooms the room list may show. Read at once, so nothing has to wait.
@riverpod
List<RoomListEntry> roomListEntries(Ref ref) {
  ref.watch(roomChangesProvider);
  return ref.watch(getRoomListEntriesUseCaseProvider).execute();
}
