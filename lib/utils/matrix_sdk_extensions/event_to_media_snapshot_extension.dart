import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/media_album/entities/media_event_snapshot.dart';
import 'package:twake_chat/domain/media_album/policy/media_batch_stamp.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

extension EventToMediaSnapshotExtension on Event {
  String? get mediaBatchId {
    final value = content[MediaBatchStamp.contentKey];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Cheap path for the timeline pass: only an image with a batch key needs
  /// the full snapshot, everything else just ends a run.
  MediaEventSnapshot toMediaSnapshotIfBatched() => mediaBatchId == null
      ? MediaEventSnapshot(
          eventId: eventId,
          senderId: senderId,
          originServerTs: originServerTs,
        )
      : toMediaSnapshot();

  MediaEventSnapshot toMediaSnapshot() => MediaEventSnapshot(
    eventId: eventId,
    senderId: senderId,
    originServerTs: originServerTs,
    isImage: type == EventTypes.Message && messageType == MessageTypes.Image,
    isFailed: status.isError,
    isRedacted: redacted,
    inThread: relationshipType == RelationshipTypes.thread,
    isReply: isReplyEvent(),
    hasCaption: text.isNotEmpty && isBodyDiffersFromFilename(),
    batchId: mediaBatchId,
  );
}
