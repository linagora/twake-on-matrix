import 'package:fluffychat/app_state/success.dart';

class CreateRoomEndActionSuccess extends Success {
  final String roomId;

  const CreateRoomEndActionSuccess({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}
