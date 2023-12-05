import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class UpdateGroupChatInitial extends Success {
  @override
  List<Object?> get props => [];
}

class UpdateGroupChatSuccess extends Success {
  final MatrixFile? roomAvatarFile;
  final String? displayName;
  final String? description;
  final bool isDeleteAvatar;

  const UpdateGroupChatSuccess({
    this.roomAvatarFile,
    this.displayName,
    this.description,
    this.isDeleteAvatar = false,
  });

  @override
  List<Object?> get props =>
      [roomAvatarFile, displayName, description, isDeleteAvatar];
}
