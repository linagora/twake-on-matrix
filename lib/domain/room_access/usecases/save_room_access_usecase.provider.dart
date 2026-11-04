import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/room_access/repositories/room_access_repository.provider.dart';
import 'package:twake_chat/domain/room_access/usecases/save_room_access_usecase.dart';

part 'save_room_access_usecase.provider.g.dart';

@riverpod
SaveRoomAccessUseCase saveRoomAccessUseCase(Ref ref) =>
    SaveRoomAccessUseCase(ref.watch(roomAccessRepositoryProvider));
