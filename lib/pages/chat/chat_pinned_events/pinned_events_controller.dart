import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/chat_get_pinned_events_state.dart';
import 'package:fluffychat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class PinnedEventsController {
  static const _timeDelayGetPinnedMessage = Duration(seconds: 1);

  final getPinnedMessageInteractor = getIt.get<ChatGetPinnedEventsInteractor>();

  final AutoScrollController pinnedMessageScrollController =
      AutoScrollController();

  final ValueNotifier<Event?> currentPinnedEventNotifier = ValueNotifier(null);

  final ValueNotifier<Either<Failure, Success>> getPinnedMessageNotifier =
      ValueNotifier<Either<Failure, Success>>(
    Right(ChatGetPinnedEventsInitial()),
  );

  StreamSubscription? _pinnedEventsSubscription;

  bool isCurrentPinnedEvent(Event event) {
    return currentPinnedEventNotifier.value?.eventId == event.eventId;
  }

  void getPinnedMessageAction({
    required Room room,
    bool isInitial = false,
    String? eventId,
  }) async {
    await Future.delayed(_timeDelayGetPinnedMessage);
    _pinnedEventsSubscription = getPinnedMessageInteractor
        .execute(
      room: room,
    )
        .listen((event) {
      getPinnedMessageNotifier.value = event;
      event.fold((_) => null, (success) {
        if (success is ChatGetPinnedEventsSuccess) {
          if (success.pinnedEvents.isNotEmpty) {
            if (isInitial) {
              initialPinnedMessage(success.pinnedEvents);
            } else {
              jumpToCurrentMessage(
                success.pinnedEvents,
                eventId: eventId,
              );
            }
          }
        }
      });
    });
  }

  void jumpToPinnedMessageAction(
    List<Event?> pinnedEvents, {
    void Function(String)? scrollToEventId,
  }) async {
    final nextIndex = _nextIndexOfPinnedMessage(pinnedEvents);
    final event = pinnedEvents[nextIndex];
    Logs().d(
      "PinnedEventsController()::jumpToPinnedMessage(): eventID: ${event?.eventId}",
    );
    if (event != null) {
      currentPinnedEventNotifier.value = event;
      pinnedMessageScrollController.scrollToIndex(nextIndex);
      if (scrollToEventId != null) {
        scrollToEventId.call(event.eventId);
      }
    }
  }

  int currentIndexOfPinnedMessage(List<Event?> pinnedEvents) {
    final index = pinnedEvents.indexWhere(
      (event) => event?.eventId == currentPinnedEventNotifier.value?.eventId,
    );
    if (index < 0) {
      currentPinnedEventNotifier.value = pinnedEvents.first;
    }
    return index;
  }

  int _nextIndexOfPinnedMessage(List<Event?> pinnedEvents) {
    final currentIndex = currentIndexOfPinnedMessage(pinnedEvents);
    final index =
        currentIndex == 0 ? pinnedEvents.length - 1 : currentIndex - 1;
    return index;
  }

  void initialPinnedMessage(List<Event?> pinnedEvents) {
    currentPinnedEventNotifier.value = pinnedEvents.last;
    pinnedMessageScrollController.scrollToIndex(
      pinnedEvents.length - 1,
    );
  }

  void handlePopBack(Object? popResult) {
    Logs().d(
      "PinnedEventsController()::handlePopBack(): popResult: $popResult",
    );
    if (popResult is List<Event?>) {
      final room = popResult.first?.room;
      if (room != null) {
        getPinnedMessageAction(
          room: room,
          isInitial: true,
        );
      }
    }
  }

  void jumpToCurrentMessage(
    List<Event?> pinnedEvents, {
    String? eventId,
  }) async {
    final currentEvent = pinnedEvents.firstWhere(
      (event) => event?.eventId == eventId,
    );
    int index = pinnedEvents.indexOf(currentEvent);
    if (index == -1) {
      index = 0;
    }
    currentPinnedEventNotifier.value = currentEvent;
    pinnedMessageScrollController.scrollToIndex(index);
  }

  void dispose() {
    currentPinnedEventNotifier.dispose();
    getPinnedMessageNotifier.dispose();
    pinnedMessageScrollController.dispose();
    _pinnedEventsSubscription?.cancel();
  }
}
