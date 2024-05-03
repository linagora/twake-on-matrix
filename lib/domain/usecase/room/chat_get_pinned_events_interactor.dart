import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/chat_get_pinned_events_state.dart';
import 'package:matrix/matrix.dart';

class ChatGetPinnedEventsInteractor {
  Stream<Either<Failure, Success>> execute({
    required String roomId,
    required Client client,
    bool isInitial = false,
  }) async* {
    Logs().d(
      "ChatGetPinnedEventsInteractor()::execute()::roomId: $roomId",
    );
    if (isInitial) {
      yield Right(ChatGetPinnedEventsLoading());
    }
    Timeline? timeline;
    try {
      final room = client.getRoomById(roomId);
      if (room == null) {
        Logs().d(
          "ChatGetPinnedEventsInteractor()::execute(): Room is Null",
        );
        yield Left(CannotGetPinnedMessages());
        return;
      }
      if (isInitial) {
        timeline = await room.getTimeline();
      }
      final pinnedEvents = room.pinnedEventIds;
      Logs().d(
        "ChatGetPinnedEventsInteractor()::execute()::pinnedEvents: $pinnedEvents",
      );
      final result = (await Future.wait(
        pinnedEvents.map(room.getEventById),
      ))
          .nonNulls
          .toList();

      if (result.isEmpty) {
        yield Left(ChatGetPinnedEventsNoResult());
        return;
      } else {
        Logs().d(
          "ChatGetPinnedEventsInteractor()::execute()::result: ${result.length}",
        );
        result.sort((currentEvent, nextEvent) {
          final currentPinnedTime = currentEvent.originServerTs;
          final nextPinnedTime = nextEvent.originServerTs;
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
    } finally {
      timeline?.cancelSubscriptions();
    }
  }
}
