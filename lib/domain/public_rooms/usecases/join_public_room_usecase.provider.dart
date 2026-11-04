import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/join_public_room_usecase.dart';

part 'join_public_room_usecase.provider.g.dart';

@riverpod
JoinPublicRoomUseCase joinPublicRoomUseCase(Ref ref) =>
    JoinPublicRoomUseCase(ref.watch(publicRoomsRepositoryProvider));
