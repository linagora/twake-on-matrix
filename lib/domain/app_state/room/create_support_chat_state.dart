import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/presentation/state/success.dart';

class CreateSupportChatInitial extends Success {
  @override
  List<Object?> get props => [];
}

class CreatingSupportChat extends LoadingState {}

class SupportChatExisted extends Success {
  const SupportChatExisted({required this.roomId});

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

class SupportChatCreated extends Success {
  const SupportChatCreated({required this.roomId});

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

class CreateSupportChatFailed extends Failure {
  const CreateSupportChatFailed({required this.exception});

  final dynamic exception;

  @override
  List<Object?> get props => [exception];
}
