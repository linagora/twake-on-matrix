import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/room_access/datasources_impl/room_access_datasource.provider.dart';
import 'package:twake_chat/data/room_access/repositories/room_access_repository_impl.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';

part 'room_access_repository.provider.g.dart';

@riverpod
RoomAccessRepository roomAccessRepository(Ref ref) =>
    RoomAccessRepositoryImpl(ref.watch(roomAccessDatasourceProvider));
