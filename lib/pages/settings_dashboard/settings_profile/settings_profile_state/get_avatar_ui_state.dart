import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_state/settings_profile_ui_state.dart';
import 'package:matrix/matrix.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class GetAvatarInitialUIState extends SettingsProfileUIState {}

class GetAvatarInStreamUIStateSuccess extends SettingsProfileUIState {
  final AssetEntity? assetEntity;

  GetAvatarInStreamUIStateSuccess({
    this.assetEntity,
  });

  @override
  List<Object?> get props => [assetEntity];
}

class GetAvatarInBytesUIStateSuccess extends SettingsProfileUIState {
  final MatrixFile? matrixFile;

  GetAvatarInBytesUIStateSuccess({this.matrixFile});

  @override
  List<Object?> get props => [matrixFile];
}
