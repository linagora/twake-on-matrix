import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/public_rooms/public_rooms_datasource.dart';
import 'package:twake_chat/data/datasource_impl/public_rooms/public_rooms_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'public_rooms_datasource.provider.g.dart';

@riverpod
PublicRoomsDatasource publicRoomsDatasource(Ref ref) =>
    PublicRoomsDatasourceImpl(
      ref.watch(
        activeMatrixClientProvider.select((snapshot) => snapshot.client),
      ),
    );
