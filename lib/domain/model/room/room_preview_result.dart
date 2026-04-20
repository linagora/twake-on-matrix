import 'package:matrix/matrix.dart';

/// Result of [RoomExtension.lastEventAvailableInPreview].
///
/// Three states are possible:
/// - [RoomPreviewFound]       — an eligible event was found.
/// - [RoomPreviewEmpty]       — the full history was scanned (m.room.create
///                              was reached) with no eligible event: the room
///                              has never had a previewable message.
/// - [RoomPreviewUnavailable] — the scan window was exhausted before reaching
///                              m.room.create: eligible events may exist
///                              further in history.
sealed class RoomPreviewResult {
  const RoomPreviewResult();
}

final class RoomPreviewFound extends RoomPreviewResult {
  final Event event;
  const RoomPreviewFound(this.event);
}

final class RoomPreviewEmpty extends RoomPreviewResult {
  const RoomPreviewEmpty();
}

final class RoomPreviewUnavailable extends RoomPreviewResult {
  const RoomPreviewUnavailable();
}
