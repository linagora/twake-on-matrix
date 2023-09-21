import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class TimelineSearchEventInitial extends Success {
  @override
  List<Object?> get props => [];
}

class TimelineSearchEventSuccess extends Success {
  final List<Event> events;

  const TimelineSearchEventSuccess({required this.events});

  @override
  List<Object?> get props => [events];

  @override
  String toString() {
    return "TimelineSearchEventSuccess ${events.length} ${events.map((event) => event.eventId)}";
  }
}

class TimelineSearchEventFailure extends Failure {
  final dynamic exception;

  const TimelineSearchEventFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

extension TimelineSearchEventSuccessExtension on TimelineSearchEventSuccess {
  TimelineSearchEventSuccess concat(TimelineSearchEventSuccess other) {
    return TimelineSearchEventSuccess(
      events: events + other.events,
    );
  }
}
