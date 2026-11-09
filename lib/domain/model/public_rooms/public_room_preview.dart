import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';

part 'public_room_preview.freezed.dart';

@freezed
sealed class PublicRoomPreview with _$PublicRoomPreview {
  const factory PublicRoomPreview.found(
    PublicRoom room, {
    @Default(false) bool isRequested,
  }) = PublicRoomPreviewFound;

  /// Joined or invited under another address than the one of the link.
  const factory PublicRoomPreview.joined(String roomId) =
      PublicRoomPreviewJoined;

  const factory PublicRoomPreview.banned() = PublicRoomPreviewBanned;

  /// The room cannot be previewed: unknown, invite only, or not reachable.
  const factory PublicRoomPreview.unavailable() = PublicRoomPreviewUnavailable;
}
