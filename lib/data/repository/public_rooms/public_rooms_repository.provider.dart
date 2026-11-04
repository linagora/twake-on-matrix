import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/public_rooms/public_rooms_datasource.provider.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository_impl.dart';
import 'package:twake_chat/domain/repository/public_rooms/public_rooms_repository.dart';

part 'public_rooms_repository.provider.g.dart';

@riverpod
PublicRoomsRepository publicRoomsRepository(Ref ref) =>
    PublicRoomsRepositoryImpl(ref.watch(publicRoomsDatasourceProvider));
