import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';

part 'public_room_preview_state.freezed.dart';

@freezed
abstract class PublicRoomPreviewState with _$PublicRoomPreviewState {
  const PublicRoomPreviewState._();

  const factory PublicRoomPreviewState({
    required PublicRoomPreview preview,
    @Default(false) bool isPending,
    @Default(false) bool hasFailed,
  }) = _PublicRoomPreviewState;

  /// Not busy, and the room is one to join or to ask for.
  bool get canOpen =>
      !isPending &&
      switch (preview) {
        PublicRoomPreviewFound(:final isRequested) => !isRequested,
        PublicRoomPreviewUnavailable() => true,
        PublicRoomPreviewBanned() || PublicRoomPreviewJoined() => false,
      };
}
