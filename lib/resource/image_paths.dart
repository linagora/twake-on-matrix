import 'package:fluffychat/resource/assets_paths.dart';

class ImagePaths {
  static String get icAddFile => _getImagePath('ic_add_file.svg');
  static String get icAdd => _getImagePath('ic_add.svg');
  static String get icDone => _getImagePath('ic_done.svg');
  static String get icEmoji => _getImagePath('ic_emoji.svg');
  static String get icPhoneCall => _getImagePath('ic_phone_call.svg');
  static String get icReadStatus => _getImagePath('ic_read_status.svg');
  static String get icSendStatus => _getImagePath('ic_send_status.svg');
  static String get icSend => _getImagePath('ic_send.svg');
  static String get icSending => _getImagePath('ic_sending.svg');
  static String get icVideoCall => _getImagePath('ic_video_call.svg');
  static String get icVoiceMessage => _getImagePath('ic_voice_message.svg');
  static String get icKeyBoard => _getImagePath('ic_keyboard.svg');
  static String get icSkeletons => _getImagePath('ic_skeletons.svg');
  static String get icStatus => _getImagePath('ic_status.svg');
  static String get icEmptyGroupChat => _getImagePath('ic_empty_group_chat.svg');
  static String get icTwakeLogo => _getImagePath('ic_twake_logo.svg');
  static String get icPhotosSettingPermission => _getImagePath('ic_photos_setting.svg');

  static String _getImagePath(String imageName) {
    return AssetsPaths.images + imageName;
  }
}
