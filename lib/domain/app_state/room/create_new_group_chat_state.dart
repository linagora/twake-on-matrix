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
  final String? groupName;

  const CreateNewGroupChatSuccess({
    required this.roomId,
    this.groupName,
  });

  @override
  List<Object?> get props => [roomId, groupName];
}

class CreateNewGroupChatFailed extends Failure {
  final dynamic exception;

  const CreateNewGroupChatFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}
