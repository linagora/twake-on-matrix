import 'package:fluffychat/app_state/success.dart';

class UpdateProfileInitial extends Success {
  @override
  List<Object?> get props => [];
}

class UpdateProfileSuccess extends Success {
  final Uri? avatar;
  final String? displayName;

  const UpdateProfileSuccess({
    this.avatar,
    this.displayName,
  });

  @override
  List<Object?> get props => [avatar, displayName];
}

class DeleteProfileSuccess extends Success {
  final String? displayName;

  const DeleteProfileSuccess({
    this.displayName,
  });
  @override
  List<Object?> get props => [displayName];
}
