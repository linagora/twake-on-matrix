import 'package:fluffychat/app_state/success.dart';

class UpdateGroupChatInitial extends Success {
  @override
  List<Object?> get props => [];
}

class UpdateAvatarGroupChatSuccess extends Success {
  final bool isDeleteAvatar;

  const UpdateAvatarGroupChatSuccess(this.isDeleteAvatar);

  @override
  List<Object?> get props => [isDeleteAvatar];
}

class UpdateDisplayNameGroupChatSuccess extends Success {
  const UpdateDisplayNameGroupChatSuccess();

  @override
  List<Object?> get props => [];
}

class UpdateDescriptionGroupChatSuccess extends Success {
  const UpdateDescriptionGroupChatSuccess();

  @override
  List<Object?> get props => [];
}
