import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/get_knocked_public_room_ids_usecase.dart';

part 'get_knocked_public_room_ids_usecase.provider.g.dart';

@riverpod
GetKnockedPublicRoomIdsUseCase getKnockedPublicRoomIdsUseCase(Ref ref) =>
    GetKnockedPublicRoomIdsUseCase(ref.watch(publicRoomsRepositoryProvider));
