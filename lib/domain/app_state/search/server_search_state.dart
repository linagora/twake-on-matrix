import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class ServerSearchInitial extends Initial {
  @override
  List<Object?> get props => [];
}

class ServerSearchChatSuccess extends Success {
  final String? roomId;
  final List<Result>? results;
  final String? nextBatch;

  const ServerSearchChatSuccess({
    this.results,
    this.nextBatch,
    this.roomId,
  });

  @override
  List<Object?> get props => [
        results,
        nextBatch,
        roomId,
      ];
}

class ServerSearchChatFailed extends Failure {
  final dynamic exception;

  const ServerSearchChatFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}
