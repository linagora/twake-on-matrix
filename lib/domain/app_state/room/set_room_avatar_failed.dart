import 'package:fluffychat/app_state/failure.dart';

class SetRoomAvatarFailed extends Failure {
  final dynamic exception;

  const SetRoomAvatarFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}