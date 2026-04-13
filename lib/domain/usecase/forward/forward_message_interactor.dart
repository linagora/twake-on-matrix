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
      yield Right(ForwardMessageLoading());

      int successCount = 0;
      final totalCount = selectedEvents.length;

      for (final roomId in selectedEvents) {
        try {
          final room = rooms.firstWhereOrNull(
            (element) => element.id == roomId,
          );
          if (room == null || room.membership != Membership.join) continue;

          if (matrixState.shareContentList.isEmpty &&
              matrixState.shareContent != null) {
            yield* _forwardOneMessageAction(
              room: room,
              matrixState: matrixState,
            );
          } else {
            yield* _forwardMultipleMessagesAction(
              room: room,
              matrixState: matrixState,
            );
          }
          successCount++;
          yield Right(ForwardMessageSuccess(room));
        } catch (exception) {
          yield Left(ForwardMessageFailed(exception: exception));
        }
      }

      matrixState.shareContent = null;
      matrixState.shareContentList = null;

      yield Right(
        ForwardMessageAllDoneState(
          successCount: successCount,
          totalCount: totalCount,
        ),
      );
    } catch (exception) {
      yield Left(ForwardMessageFailed(exception: exception));
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
    required MatrixState matrixState,
  }) async* {
    final message = matrixState.shareContent;
    if (message != null) {
      yield* _forwardMessage(message, room);
    }
  }

  Stream<Either<Failure, Success>> _forwardMultipleMessagesAction({
    required Room room,
    required MatrixState matrixState,
  }) async* {
    final messages = matrixState.shareContentList;
    if (messages.isNotEmpty) {
      for (final message in messages) {
        if (message != null) {
          yield* _forwardMessage(message, room);
        }
      }
    }
  }
}
