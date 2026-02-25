import 'package:fluffychat/app_state/failure.dart';

class CreateDirectChatFailed extends Failure {
  final dynamic exception;

  const CreateDirectChatFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class NoPermissionForCreateChat extends Failure {
  const NoPermissionForCreateChat();

  @override
  List<Object?> get props => [];
}
