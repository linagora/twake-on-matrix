import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/fetch_joinable_public_rooms_usecase.dart';

part 'fetch_joinable_public_rooms_usecase.provider.g.dart';

@riverpod
FetchJoinablePublicRoomsUseCase fetchJoinablePublicRoomsUseCase(Ref ref) =>
    FetchJoinablePublicRoomsUseCase(ref.watch(publicRoomsRepositoryProvider));
