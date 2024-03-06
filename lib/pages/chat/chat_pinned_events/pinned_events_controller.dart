import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/chat_get_pinned_events_state.dart';
import 'package:fluffychat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

typedef JumpToPinnedMessageCallback = void Function(int index);

class PinnedEventsController {
  static const _timeDelayGetPinnedMessage = Duration(seconds: 1);

  final getPinnedMessageInteractor = getIt.get<ChatGetPinnedEventsInteractor>();

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
    required String roomId,
    required Client client,
    bool isInitial = false,
    bool isUnpin = false,
    String? eventId,
    JumpToPinnedMessageCallback? jumpToPinnedMessageCallback,
  }) async {
    await Future.delayed(_timeDelayGetPinnedMessage);
    _pinnedEventsSubscription = getPinnedMessageInteractor
        .execute(
      roomId: roomId,
      client: client,
      isInitial: isInitial,
    )
        .listen((event) {
      try {
        getPinnedMessageNotifier.value = event;
        event.fold((_) => null, (success) {
          if (success is ChatGetPinnedEventsSuccess) {
            if (success.pinnedEvents.isNotEmpty) {
              if (isInitial || isUnpin) {
                updatePinnedMessage(
                  success.pinnedEvents,
                  jumpToPinnedMessageCallback: jumpToPinnedMessageCallback,
                );
              } else {
                jumpToCurrentMessage(
                  success.pinnedEvents,
                  eventId: eventId,
                  jumpToPinnedMessageCallback: jumpToPinnedMessageCallback,
                );
              }
            }
          }
        });
      } on FlutterError catch (error) {
        Logs().e(
          "PinnedEventsController()::getPinnedMessageAction(): FlutterError: $error",
        );
      }
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
      return 0;
    }
    return index;
  }

  int _nextIndexOfPinnedMessage(List<Event?> pinnedEvents) {
    final currentIndex = currentIndexOfPinnedMessage(pinnedEvents);
    final index =
        currentIndex == 0 ? pinnedEvents.length - 1 : currentIndex - 1;
    return index;
  }

  void updatePinnedMessage(
    List<Event?> pinnedEvents, {
    JumpToPinnedMessageCallback? jumpToPinnedMessageCallback,
  }) {
    currentPinnedEventNotifier.value = pinnedEvents.last;
    if (pinnedEvents.isNotEmpty) {
      jumpToPinnedMessageCallback?.call(
        pinnedEvents.length - 1,
      );
    }
  }

  void handlePopBack({
    required Client client,
    Object? popResult,
  }) {
    Logs().d(
      "PinnedEventsController()::handlePopBack(): popResult: $popResult",
    );
    if (popResult is List<Event?>) {
      if (popResult.isEmpty) {
        return;
      }
      final room = popResult.first?.room;
      if (room != null) {
        getPinnedMessageAction(
          roomId: room.id,
          client: client,
        );
      }
    }
  }

  void jumpToCurrentMessage(
    List<Event?> pinnedEvents, {
    JumpToPinnedMessageCallback? jumpToPinnedMessageCallback,
    String? eventId,
  }) async {
    final currentEvent = pinnedEvents.firstWhereOrNull(
      (event) => event?.eventId == eventId,
    );
    if (currentEvent == null) return;
    int index = pinnedEvents.indexOf(currentEvent);
    if (index == -1) {
      index = 0;
    }
    currentPinnedEventNotifier.value = currentEvent;
    jumpToPinnedMessageCallback?.call(index);
  }

  void dispose() {
    currentPinnedEventNotifier.dispose();
    getPinnedMessageNotifier.dispose();
    _pinnedEventsSubscription?.cancel();
  }
}
