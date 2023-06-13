import 'package:fluffychat/app_state/failure.dart';

class CreateRoomFailed extends Failure {
  final dynamic exception;

  const CreateRoomFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}