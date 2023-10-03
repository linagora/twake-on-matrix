import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_state/settings_profile_ui_state.dart';
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
  final FilePickerResult? filePickerResult;

  GetAvatarInBytesUIStateSuccess({this.filePickerResult});

  @override
  List<Object?> get props => [filePickerResult];
}
