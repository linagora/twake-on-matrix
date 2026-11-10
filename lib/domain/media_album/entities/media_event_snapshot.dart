import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_event_snapshot.freezed.dart';

/// What the album policy needs to know about one timeline event.
/// Carries ids and flags only, never file URLs or keys.
@freezed
abstract class MediaEventSnapshot with _$MediaEventSnapshot {
  const factory MediaEventSnapshot({
    required String eventId,
    required String senderId,
    required DateTime originServerTs,
    @Default(false) bool isImage,
    @Default(false) bool isFailed,
    @Default(false) bool isRedacted,
    @Default(false) bool inThread,
    @Default(false) bool isReply,
    @Default(false) bool hasCaption,
    String? batchId,
  }) = _MediaEventSnapshot;
}
