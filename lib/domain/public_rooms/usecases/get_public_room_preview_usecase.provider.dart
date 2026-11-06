import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/get_public_room_preview_usecase.dart';

part 'get_public_room_preview_usecase.provider.g.dart';

@riverpod
GetPublicRoomPreviewUseCase getPublicRoomPreviewUseCase(Ref ref) =>
    GetPublicRoomPreviewUseCase(ref.watch(publicRoomsRepositoryProvider));
