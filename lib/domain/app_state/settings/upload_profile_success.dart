import 'package:fluffychat/app_state/success.dart';

class UploadProfileInitial extends Success {
  @override
  List<Object?> get props => [];
}

class UploadProfileSuccess extends Success {
  final Uri? avatar;
  final String? displayName;

  const UploadProfileSuccess({
    this.avatar,
    this.displayName,
  });

  @override
  List<Object?> get props => [avatar, displayName];
}
