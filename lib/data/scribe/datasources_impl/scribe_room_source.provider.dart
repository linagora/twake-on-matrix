import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_room_source_impl.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_room_source.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'scribe_room_source.provider.g.dart';

@riverpod
ScribeRoomSource scribeRoomSource(Ref ref) =>
    ScribeRoomSourceImpl(ref.watch(activeMatrixClientProvider));
