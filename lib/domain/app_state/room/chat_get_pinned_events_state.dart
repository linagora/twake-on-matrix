import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class ChatGetPinnedEventsInitial extends Initial {
  @override
  List<Object?> get props => [];
}

class ChatGetPinnedEventsLoading extends Success {
  @override
  List<Object?> get props => [];
}

class ChatGetPinnedEventsSuccess extends Success {
  final List<Event?> pinnedEvents;

  const ChatGetPinnedEventsSuccess({
    required this.pinnedEvents,
  });

  @override
  List<Object?> get props => [pinnedEvents];
}

class ChatGetPinnedEventsNoResult extends Failure {
  @override
  List<Object?> get props => [];
}

class CannotGetPinnedMessages extends Failure {
  @override
  List<Object?> get props => [];
}

class ChatGetPinnedEventsFailure extends Failure {
  final dynamic exception;

  const ChatGetPinnedEventsFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}
