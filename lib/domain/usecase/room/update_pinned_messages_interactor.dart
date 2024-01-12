import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/update_pinned_events_state.dart';
import 'package:fluffychat/domain/enums/pinned_messages_action_enum.dart';
import 'package:matrix/matrix.dart';

class UpdatePinnedMessagesInteractor {
  Stream<Either<Failure, Success>> execute({
    required Room room,
    required List<String> eventIds,
    PinnedMessagesActionEnum action = PinnedMessagesActionEnum.unpin,
  }) async* {
    try {
      yield Right(UpdatePinnedEventsInitial());
      final currentPinnedEvents = room.pinnedEventIds.toSet();
      switch (action) {
        case PinnedMessagesActionEnum.pin:
          currentPinnedEvents.addAll(eventIds);
          break;
        case PinnedMessagesActionEnum.unpin:
          currentPinnedEvents.removeAll(eventIds);
          break;
        case PinnedMessagesActionEnum.unpinAll:
          currentPinnedEvents.clear();
          break;
      }
      final result = await room.setPinnedEvents(currentPinnedEvents.toList());
      yield Right(UpdatePinnedEventsSuccess(result));
    } on MatrixException catch (exception) {
      Logs().e(
        'UpdatePinnedMessagesInteractor::execute(): ErrorCode ${exception.errcode}: ${exception.errorMessage}',
      );
      yield Left(
        UpdatePinnedEventsFailure(exception),
      );
    } catch (e) {
      if (action == PinnedMessagesActionEnum.pin) {
        yield Left(PinEventsFailure(e));
      } else {
        yield Left(UnpinEventsFailure(e));
      }
    }
  }
}
