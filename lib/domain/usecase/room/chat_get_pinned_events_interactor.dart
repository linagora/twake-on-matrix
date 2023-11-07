import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/chat_get_pinned_events_state.dart';
import 'package:matrix/matrix.dart';

class ChatGetPinnedEventsInteractor {
  Stream<Either<Failure, Success>> execute({
    required Room room,
  }) async* {
    Logs().d(
      "ChatGetPinnedEventsInteractor()::execute()::roomId: ${room.id}",
    );
    yield Right(ChatGetPinnedEventsLoading());
    try {
      final pinnedEvents = room.pinnedEventIds;
      final result = await Future.wait(
        pinnedEvents.map(room.getEventById),
      );

      if (result.isEmpty) {
        yield Left(ChatGetPinnedEventsNoResult());
        return;
      } else {
        Logs().d(
          "ChatGetPinnedEventsInteractor()::execute()::result: ${result.length}",
        );
        result.sort((currentEvent, nextEvent) {
          final currentPinnedTime =
              currentEvent?.originServerTs ?? DateTime.now();
          final nextPinnedTime = nextEvent?.originServerTs ?? DateTime.now();
          return currentPinnedTime.compareTo(nextPinnedTime);
        });
        yield Right(ChatGetPinnedEventsSuccess(pinnedEvents: result));
        return;
      }
    } on MatrixException catch (exception) {
      Logs().e(
        "ChatGetPinnedEventsInteractor()::execute()::MatrixException: ${exception.error}",
      );
      yield Left(ChatGetPinnedEventsFailure(exception: exception));
    } catch (exception) {
      Logs().e(
        "ChatGetPinnedEventsInteractor()::execute()::Exception: $exception",
      );
      yield Left(ChatGetPinnedEventsFailure(exception: exception));
    }
  }
}
