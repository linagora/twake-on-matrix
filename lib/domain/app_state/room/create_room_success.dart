import 'package:fluffychat/app_state/success.dart';

class CreateRoomSuccess extends Success {
  final String roomId;

  const CreateRoomSuccess({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}
