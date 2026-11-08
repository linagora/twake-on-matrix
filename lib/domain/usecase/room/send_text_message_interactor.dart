import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/services/message_splitter.dart';
import 'package:twake_chat/domain/services/room_send_queue_service.dart';

/// Sends a composer text, split into several messages when it is longer than
/// [MessageSplitter.maxLength]. Parts are sent one after the other, the reply
/// goes on the first one, and a failed part does not stop the next ones.
/// Edits and commands are never split. Sends go through [sendQueue], so a
/// text sent meanwhile cannot land between two parts.
final class SendTextMessageInteractor {
  const SendTextMessageInteractor({
    required this.splitter,
    required this.sendQueue,
  });

  final MessageSplitter splitter;

  final RoomSendQueueService sendQueue;

  /// Completes once the text is sent, after the sends queued before it in
  /// the same room. Throws when an edit or a command fails, a failed part is
  /// only logged.
  Future<void> execute({
    required Room room,
    required String text,
    Event? inReplyTo,
    String? editEventId,
    String? threadRootEventId,
    String? threadLastEventId,
  }) => sendQueue.enqueue(
    room.id,
    () => _send(
      room: room,
      text: text,
      inReplyTo: inReplyTo,
      editEventId: editEventId,
      threadRootEventId: threadRootEventId,
      threadLastEventId: threadLastEventId,
    ),
  );

  Future<void> _send({
    required Room room,
    required String text,
    Event? inReplyTo,
    String? editEventId,
    String? threadRootEventId,
    String? threadLastEventId,
  }) async {
    // A quote in a thread would be prepended to the body by the SDK.
    if (threadRootEventId != null) inReplyTo = null;
    final bool isCommand = _isKnownCommand(room, text);
    if (editEventId != null || isCommand) {
      await room.sendTextEvent(
        text,
        inReplyTo: inReplyTo,
        editEventId: editEventId,
        parseCommands: isCommand,
        // An edit copies the thread relation into `m.new_content`: it is not
        // a reply.
        threadRootEventId: editEventId == null ? threadRootEventId : null,
        threadLastEventId: editEventId == null ? threadLastEventId : null,
      );
      return;
    }

    final List<String> parts = splitter.split(text);
    for (final (int index, String part) in parts.indexed) {
      try {
        final String? sentId = await room.sendTextEvent(
          part,
          inReplyTo: index == 0 ? inReplyTo : null,
          // A part starting with "/" is not a command.
          parseCommands: false,
          threadRootEventId: threadRootEventId,
          threadLastEventId: threadLastEventId,
        );
        // The next part follows this one in the thread.
        if (sentId != null && threadRootEventId != null) {
          threadLastEventId = sentId;
        }
      } on Exception catch (error, stackTrace) {
        // The part is already in error in the timeline, keep going.
        Logs().e(
          'SendTextMessageInteractor::_send(): part '
          '${index + 1}/${parts.length} failed in room ${room.id}',
          error,
          stackTrace,
        );
      }
    }
  }

  bool _isKnownCommand(Room room, String text) {
    if (!text.startsWith('/')) return false;
    final String name = text.substring(1).split(' ').first.toLowerCase();
    return room.client.commands.containsKey(name);
  }
}
