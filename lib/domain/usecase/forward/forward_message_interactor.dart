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

      final room =
          rooms.firstWhere((element) => element.id == selectedEvents.first);
      if (room.membership == Membership.join) {
        if (matrixState.shareContentList.isEmpty &&
            matrixState.shareContent != null) {
          yield* _forwardOneMessageAction(room: room, matrixState: matrixState);
        } else {
          yield* _forwardMultipleMessagesAction(
            room: room,
            matrixState: matrixState,
          );
        }
      }
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
    try {
      final message = matrixState.shareContent;
      if (message != null) {
        yield* _forwardMessage(message, room);
        matrixState.shareContent = null;
      }
      yield Right(ForwardMessageSuccess(room));
    } catch (exception) {
      yield Left(ForwardMessageFailed(exception: exception));
    }
  }

  Stream<Either<Failure, Success>> _forwardMultipleMessagesAction({
    required Room room,
    required MatrixState matrixState,
  }) async* {
    try {
      yield Right(ForwardMessageLoading());

      final messages = matrixState.shareContentList;
      if (messages.isNotEmpty) {
        for (final message in messages) {
          if (message != null) {
            yield* _forwardMessage(message, room);
          } else {
            continue;
          }
        }
        matrixState.shareContentList = null;
      }
      yield Right(ForwardMessageSuccess(room));
    } catch (exception) {
      yield Left(ForwardMessageFailed(exception: exception));
    }
  }
}
