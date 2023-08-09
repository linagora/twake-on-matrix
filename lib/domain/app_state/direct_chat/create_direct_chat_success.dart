import 'package:fluffychat/app_state/success.dart';

class CreateDirectChatSuccess extends Success {
  final String roomId;

  const CreateDirectChatSuccess({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}
