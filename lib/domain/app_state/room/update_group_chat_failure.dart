import 'package:fluffychat/app_state/failure.dart';

class UpdateGroupChatFailure extends Failure {
  final dynamic exception;

  const UpdateGroupChatFailure(this.exception) : super();

  @override
  List<Object?> get props => [exception];
}
