import 'package:fluffychat/app_state/success.dart';

class SetRoomAvatarSuccess extends Success {
  final String roomAvatarEventId;

  const SetRoomAvatarSuccess({required this.roomAvatarEventId});

  @override
  List<Object?> get props => [roomAvatarEventId];
}