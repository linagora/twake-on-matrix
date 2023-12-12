import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/presentation/state/success.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

abstract class ChatDetailsUploadAvatarUIState extends UIState {}

class ChatDetailsUploadAvatarInitial extends ChatDetailsUploadAvatarUIState {
  @override
  List<Object?> get props => [];
}

class ChatDetailsGetAvatarInStreamSuccess
    extends ChatDetailsUploadAvatarUIState {
  final AssetEntity assetEntity;

  ChatDetailsGetAvatarInStreamSuccess(this.assetEntity);
  @override
  List<Object?> get props => [assetEntity];
}

class ChatDetailsGetAvatarInByteSuccess extends ChatDetailsUploadAvatarUIState {
  final FilePickerResult filePickerResult;

  ChatDetailsGetAvatarInByteSuccess(this.filePickerResult);
  @override
  List<Object?> get props => [filePickerResult];
}

class ChatDetailsDeleteAvatarSuccess extends ChatDetailsUploadAvatarUIState {
  @override
  List<Object?> get props => [];
}
