import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_album.freezed.dart';

/// Two or more images of one send, oldest first.
@freezed
abstract class MediaAlbum with _$MediaAlbum {
  const MediaAlbum._();

  /// [hiddenEventIds] are deleted images between two of [eventIds]: they
  /// neither split the album nor show as a message of their own.
  const factory MediaAlbum({
    required List<String> eventIds,
    @Default([]) List<String> hiddenEventIds,
  }) = _MediaAlbum;

  /// The member that draws the album: the oldest one. Its id stays the same
  /// while the other images finish uploading, so their uploads do not rebuild
  /// the bubble. It changes once, when the leader itself is sent.
  String get leaderEventId => eventIds.first;
}
