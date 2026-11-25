import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_room_source.provider.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';

part 'scribe_room_provider.g.dart';

@riverpod
Stream<ScribeRoom> scribeRoom(Ref ref, String roomId) =>
    ref.watch(scribeRoomSourceProvider).watchRoom(roomId);
