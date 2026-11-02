import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/room_access/room_access_repository.provider.dart';
import 'package:twake_chat/domain/room_access/usecases/get_room_access_usecase.dart';

part 'get_room_access_usecase.provider.g.dart';

@riverpod
GetRoomAccessUseCase getRoomAccessUseCase(Ref ref) =>
    GetRoomAccessUseCase(ref.watch(roomAccessRepositoryProvider));
