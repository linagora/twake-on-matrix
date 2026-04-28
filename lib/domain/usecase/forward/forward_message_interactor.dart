import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/forward/forward_message_state.dart';
import 'package:fluffychat/event/twake_event_types.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:matrix/matrix.dart';

class ForwardMessageInteractor {
  Stream<Either<Failure, Success>> execute({
    required List<Room> rooms,
    required List<String> selectedEvents,
    required MatrixState matrixState,
  }) async* {
    try {
      final singleMessage = matrixState.shareContent;
      final messages = List<Map<String, dynamic>?>.from(
        matrixState.shareContentList,
      );
      final hasMultipleMessages = messages.any((message) => message != null);
      final hasContent = singleMessage != null || hasMultipleMessages;

      if (!hasContent) {
        yield Left(ForwardEmptyContentFailure());
        return;
      }

      yield Right(ForwardMessageLoading());

      int successCount = 0;
      final totalCount = selectedEvents.length;

      for (final roomId in selectedEvents) {
        try {
          final room = rooms.firstWhereOrNull(
            (element) => element.id == roomId,
          );
          if (room == null || room.membership != Membership.join) continue;

          if (!hasMultipleMessages && singleMessage != null) {
            yield* _forwardOneMessageAction(room: room, message: singleMessage);
          } else {
            yield* _forwardMultipleMessagesAction(
              room: room,
              messages: messages,
            );
          }
          successCount++;
          yield Right(ForwardMessageSuccess(room));
        } catch (exception) {
          yield Left(ForwardMessageFailed(exception: exception));
        }
      }

      yield Right(
        ForwardMessageAllDoneState(
          successCount: successCount,
          totalCount: totalCount,
        ),
      );
    } catch (exception) {
      yield Left(ForwardMessageFailed(exception: exception));
    } finally {
      matrixState.shareContent = null;
      matrixState.shareContentList = null;
    }
  }

  Stream<Either<Failure, Success>> _forwardMessage(
    Map<String, dynamic> message,
    Room room,
  ) async* {
    final shareFile = message.tryGet<MatrixFile>('file');
    if (message.tryGet<String>('msgtype') ==
            TwakeEventTypes.shareFileEventType &&
        shareFile != null) {
      yield Right(
        ForwardMessageIsShareFileState(shareFile: shareFile, room: room),
      );
    }
    await room.sendEvent(message);
  }

  Stream<Either<Failure, Success>> _forwardOneMessageAction({
    required Room room,
    required Map<String, dynamic> message,
  }) async* {
    yield* _forwardMessage(message, room);
  }

  Stream<Either<Failure, Success>> _forwardMultipleMessagesAction({
    required Room room,
    required List<Map<String, dynamic>?> messages,
  }) async* {
    for (final message in messages) {
      if (message != null) {
        yield* _forwardMessage(message, room);
      }
    }
  }
}
