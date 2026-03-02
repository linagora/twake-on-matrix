import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:matrix/matrix.dart';

extension SendFileFakeEventExtension on Room {
  Future<SyncUpdate> sendFakeFileInfoEvent(
    FileInfo fileInfo, {
    String messageType = MessageTypes.Image,
    required String txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
    DateTime? sentDate,
    String? captionInfo,
    Map<String, dynamic>? uploadInfo,
  }) async {
    final contentFromCaption = getEventContentFromMsgText(
      message: captionInfo ?? '',
      msgtype: messageType,
    );

    final contentCaptionFormat = contentFromCaption['formatted_body'] != null
        ? {
            'format': contentFromCaption['format'],
            'formatted_body': contentFromCaption['formatted_body'],
          }
        : null;
    // Create a fake Event object as a placeholder for the uploading file:
    final fakeImageEvent = SyncUpdate(
      nextBatch: '',
      rooms: RoomsUpdate(
        join: {
          id: JoinedRoomUpdate(
            timeline: TimelineUpdate(
              events: [
                MatrixEvent(
                  content: {
                    'msgtype': messageType,
                    'body': captionInfo ?? '',
                    'filename': fileInfo.fileName,
                    'info': <String, dynamic>{...fileInfo.metadata},
                    if (contentCaptionFormat != null) ...contentCaptionFormat,
                    if (extraContent != null) ...extraContent,
                  },
                  type: EventTypes.Message,
                  eventId: txid,
                  senderId: client.userID!,
                  originServerTs: sentDate ?? DateTime.now(),
                  unsigned: {
                    messageSendingStatusKey: EventStatus.sending.intValue,
                    'transaction_id': txid,
                    if (inReplyTo?.eventId != null)
                      'in_reply_to': inReplyTo?.eventId,
                    if (editEventId != null) 'edit_event_id': editEventId,
                    if (shrinkImageMaxDimension != null)
                      'shrink_image_max_dimension': shrinkImageMaxDimension,
                    if (extraContent != null) 'extra_content': extraContent,
                    if (uploadInfo != null) 'upload_info': uploadInfo,
                  },
                ),
              ],
            ),
          ),
        },
      ),
    );
    await handleFakeSync(fakeImageEvent);
    return fakeImageEvent;
  }

  Future<void> handleFakeSync(
    SyncUpdate fakeImageEvent, {
    Direction? direction,
  }) async {
    await client.database.transaction(() async {
      await client.handleSync(fakeImageEvent, direction: direction);
    });
  }

  Future<void> updateFakeSync(
    SyncUpdate fakeImageEvent,
    String key,
    Object? value,
  ) async {
    fakeImageEvent
            .rooms!
            .join!
            .values
            .first
            .timeline!
            .events!
            .first
            .unsigned![key] =
        value;
    await handleFakeSync(fakeImageEvent);
  }

  Future<void> sendFakeMessage({
    required Map<String, Object?> content,
    required String messageId,
  }) async {
    final sentDate = DateTime.now();
    final syncUpdate = SyncUpdate(
      nextBatch: '',
      rooms: RoomsUpdate(
        join: {
          id: JoinedRoomUpdate(
            timeline: TimelineUpdate(
              events: [
                MatrixEvent(
                  content: content,
                  type: EventTypes.Message,
                  eventId: messageId,
                  senderId: client.userID!,
                  originServerTs: sentDate,
                  unsigned: {
                    messageSendingStatusKey: EventStatus.sending.intValue,
                    'transaction_id': messageId,
                  },
                ),
              ],
            ),
          ),
        },
      ),
    );
    await handleFakeSync(syncUpdate);
  }

  Future<SyncUpdate> sendFakeFileEvent(
    MatrixFile file, {
    required String txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
    DateTime? sentDate,
    String? captionInfo,
    Map<String, dynamic>? uploadInfo,
  }) async {
    final contentFromCaption = getEventContentFromMsgText(
      message: captionInfo ?? '',
      msgtype: file.msgType,
    );

    final contentCaptionFormat = contentFromCaption['formatted_body'] != null
        ? {
            'format': contentFromCaption['format'],
            'formatted_body': contentFromCaption['formatted_body'],
          }
        : null;

    // Create a fake Event object as a placeholder for the uploading file:
    final fakeImageEvent = SyncUpdate(
      nextBatch: '',
      rooms: RoomsUpdate(
        join: {
          id: JoinedRoomUpdate(
            timeline: TimelineUpdate(
              events: [
                MatrixEvent(
                  content: {
                    'msgtype': file.msgType,
                    'body': captionInfo ?? '',
                    if (contentCaptionFormat != null) ...contentCaptionFormat,
                    'filename': file.name,
                    'info': file.info,
                  },
                  type: EventTypes.Message,
                  eventId: txid,
                  senderId: client.userID!,
                  originServerTs: sentDate ?? DateTime.now(),
                  unsigned: {
                    messageSendingStatusKey: EventStatus.sending.intValue,
                    'transaction_id': txid,
                    if (inReplyTo?.eventId != null)
                      'in_reply_to': inReplyTo?.eventId,
                    if (editEventId != null) 'edit_event_id': editEventId,
                    if (shrinkImageMaxDimension != null)
                      'shrink_image_max_dimension': shrinkImageMaxDimension,
                    if (extraContent != null) 'extra_content': extraContent,
                    if (uploadInfo != null) 'upload_info': uploadInfo,
                  },
                ),
              ],
            ),
          ),
        },
      ),
    );
    await handleImageFakeSync(fakeImageEvent);
    return fakeImageEvent;
  }

  Future<void> handleImageFakeSync(
    SyncUpdate fakeImageEvent, {
    Direction? direction,
  }) async {
    await client.database.transaction(() async {
      await client.handleSync(fakeImageEvent, direction: direction);
    });
  }
}
