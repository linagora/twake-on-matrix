import 'package:fluffychat/app_state/success.dart';

class SetRoomAvatarSuccess extends Success {
  final String roomAvatarEventId;
  final String roomId;

  const SetRoomAvatarSuccess({required this.roomId, required this.roomAvatarEventId});

  @override
  List<Object?> get props => [roomId, roomAvatarEventId];
}