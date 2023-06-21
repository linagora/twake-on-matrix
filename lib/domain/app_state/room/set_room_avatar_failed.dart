import 'package:fluffychat/app_state/failure.dart';

class SetRoomAvatarFailed extends Failure {
  final String roomId;
  final dynamic exception;

  const SetRoomAvatarFailed({required this.roomId, required this.exception});

  @override
  List<Object?> get props => [roomId, exception];
}