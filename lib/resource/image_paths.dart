import 'package:fluffychat/resource/assets_paths.dart';

class ImagePaths {
  static String get icAddFile => _getImagePath('ic_add_file.svg');
  static String get icAdd => _getImagePath('ic_add.svg');
  static String get icDone => _getImagePath('ic_done.svg');
  static String get icEmoji => _getImagePath('ic_emoji.svg');
  static String get icPhoneCall => _getImagePath('ic_phone_call.svg');
  static String get icSend => _getImagePath('ic_send.svg');
  static String get icSending => _getImagePath('ic_sending.svg');
  static String get icVideoCall => _getImagePath('ic_video_call.svg');
  static String get icVoiceMessage => _getImagePath('ic_voice_message.svg');
  static String get icKeyBoard => _getImagePath('ic_keyboard.svg');
  static String get icSkeletons => _getImagePath('ic_skeletons.svg');
  static String get icStatus => _getImagePath('ic_status.svg');
  static String get icEmptyGroupChat =>
      _getImagePath('ic_empty_group_chat.svg');
  static String get icTwakeLogo => _getImagePath('ic_twake_logo.svg');
  static String get icPhotosSettingPermission =>
      _getImagePath('ic_photos_setting.svg');
  static String get icFileDocx => _getImagePath('ic_file_doc.svg');
  static String get icFileZip => _getImagePath('ic_file_zip.svg');
  static String get icFileXlsx => _getImagePath('ic_file_excel.svg');
  static String get icFilePdf => _getImagePath('ic_file_pdf.svg');
  static String get icFilePptx => _getImagePath('ic_file_ppt.svg');
  static String get icFileFolder => _getImagePath('ic_file_folder.svg');
  static String get icFileUnKnow => _getImagePath('ic_file_unknow.svg');
  static String get icTwakeImageLogoDark =>
      _getImagePath('ic_twake_image_logo_dark.svg');
  static String get icApplicationGrid =>
      _getImagePath('ic_application_grid.svg');
  static String get icUsersOutline => _getImagePath('ic_users_outline.svg');
  static String get icReply => _getImagePath('ic_reply.svg');

  static String _getImagePath(String imageName) {
    return AssetsPaths.images + imageName;
  }
}
