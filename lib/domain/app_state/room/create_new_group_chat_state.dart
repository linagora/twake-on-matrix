import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class CreateNewGroupInitial extends Success {
  @override
  List<Object?> get props => [];
}

class CreateNewGroupChatLoading extends Success {
  @override
  List<Object?> get props => [];
}

class CreateNewGroupChatSuccess extends Success {
  final String roomId;

  const CreateNewGroupChatSuccess({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class CreateNewGroupChatFailed extends Failure {
  final dynamic exception;

  const CreateNewGroupChatFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}