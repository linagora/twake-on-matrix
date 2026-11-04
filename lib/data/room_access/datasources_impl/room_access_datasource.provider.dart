import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/room_access/datasources/room_access_datasource.dart';
import 'package:twake_chat/data/room_access/datasources_impl/room_access_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'room_access_datasource.provider.g.dart';

@riverpod
RoomAccessDatasource roomAccessDatasource(Ref ref) => RoomAccessDatasourceImpl(
  ref.watch(activeMatrixClientProvider.select((snapshot) => snapshot.client)),
);
