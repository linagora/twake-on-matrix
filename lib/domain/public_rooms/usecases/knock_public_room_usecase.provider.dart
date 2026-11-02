import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/knock_public_room_usecase.dart';

part 'knock_public_room_usecase.provider.g.dart';

@riverpod
KnockPublicRoomUseCase knockPublicRoomUseCase(Ref ref) =>
    KnockPublicRoomUseCase(ref.watch(publicRoomsRepositoryProvider));
