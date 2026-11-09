import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/watch_room_changes_usecase.dart';

part 'watch_room_changes_usecase.provider.g.dart';

@riverpod
WatchRoomChangesUseCase watchRoomChangesUseCase(Ref ref) =>
    WatchRoomChangesUseCase(ref.watch(spaceRepositoryProvider));
