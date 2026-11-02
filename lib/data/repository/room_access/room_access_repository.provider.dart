import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/room_access/room_access_datasource.provider.dart';
import 'package:twake_chat/data/repository/room_access/room_access_repository_impl.dart';
import 'package:twake_chat/domain/repository/room_access/room_access_repository.dart';

part 'room_access_repository.provider.g.dart';

@riverpod
RoomAccessRepository roomAccessRepository(Ref ref) =>
    RoomAccessRepositoryImpl(ref.watch(roomAccessDatasourceProvider));
