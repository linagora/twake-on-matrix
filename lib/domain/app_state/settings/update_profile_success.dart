import 'package:fluffychat/app_state/success.dart';

class UpdateProfileInitial extends Success {
  @override
  List<Object?> get props => [];
}

class UpdateProfileSuccess extends Success {
  final Uri? avatar;
  final String? displayName;
  final bool isDeleteAvatar;

  const UpdateProfileSuccess({
    this.avatar,
    this.displayName,
    this.isDeleteAvatar = false,
  });

  @override
  List<Object?> get props => [avatar, displayName, isDeleteAvatar];
}
