import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';

part 'public_room_preview_state.freezed.dart';

@freezed
abstract class PublicRoomPreviewState with _$PublicRoomPreviewState {
  const factory PublicRoomPreviewState({
    required PublicRoomPreview preview,
    @Default(false) bool isPending,
    @Default(false) bool hasFailed,
  }) = _PublicRoomPreviewState;
}
