import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class UpdatePinnedEventsInitial extends Success {
  @override
  List<Object?> get props => [];
}

class UpdatePinnedEventsSuccess extends Success {
  final String eventId;

  const UpdatePinnedEventsSuccess(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class UpdatePinnedEventsFailure extends Failure {
  final Exception exception;

  const UpdatePinnedEventsFailure(this.exception);

  @override
  List<Object?> get props => [exception];
}

class PinEventsFailure extends Failure {
  final Object error;

  const PinEventsFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class UnpinEventsFailure extends Failure {
  final Object error;

  const UnpinEventsFailure(this.error);

  @override
  List<Object?> get props => [error];
}
