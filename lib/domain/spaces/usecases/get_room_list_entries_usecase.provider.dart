import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/get_room_list_entries_usecase.dart';

part 'get_room_list_entries_usecase.provider.g.dart';

@riverpod
GetRoomListEntriesUseCase getRoomListEntriesUseCase(Ref ref) =>
    GetRoomListEntriesUseCase(ref.watch(spaceRepositoryProvider));
