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
  static String get icFileUnknown => _getImagePath('ic_file_unknown.svg');
  static String get icFileImage => _getImagePath('ic_file_image.svg');
  static String get icFileAudio => _getImagePath('ic_file_audio.svg');
  static String get icFileVideo => _getImagePath('ic_file_video.svg');
  static String get icTwakeImageLogo =>
      _getImagePath('ic_twake_image_logo.svg');
  static String get icApplicationGrid =>
      _getImagePath('ic_application_grid.svg');
  static String get icUsersOutline => _getImagePath('ic_users_outline.svg');
  static String get icReply => _getImagePath('ic_reply.svg');
  static String get icEmptyPage => _getImagePath('ic_empty_page.svg');
  static String get icErrorPage => _getImagePath('ic_error_page.svg');
  static String get icErrorPageBackground =>
      _getImagePath('ic_error_page_background.svg');
  static String get icNoResultsFound =>
      _getImagePath('ic_no_results_found.svg');
  static String get icEncrypted => _getImagePath('ic_encrypted.svg');
  static String get icMatrixid => _getImagePath('ic_matrixid.svg');
  static String get icUnpin => _getImagePath('ic_unpin.svg');
  static String get icJumpTo => _getImagePath('ic_jump_to.svg');
  static String get logoTwakeWelcome => _getImagePath('logo_twake_welcome.svg');
  static String get icEmptySearch => _getImagePath('ic_empty_search.svg');
  static String get icFileError => _getImagePath('ic_file_error.svg');
  static String get icGoTo => _getImagePath('ic_goto.svg');
  static String get icShowInChat => _getImagePath('ic_show_in_chat.svg');
  static String get lottieTwakeLoading => _getAssetPath('twake_loading.json');
  static String get icPersonCheck => _getImagePath('ic_person_check.svg');
  static String get icTwakeImageLogoBeta =>
      _getImagePath('ic_twake_image_beta.svg');
  static String get logoPng => _getAssetPath('logo.png');
  static String get appStore => _getImagePath('app_store.svg');
  static String get googlePlay => _getImagePath('google_play.svg');
  static String get icTwakeSupport =>
      getConfigurationImagePath('ic_twake_support.svg');

  static String _getImagePath(String imageName) {
    return AssetsPaths.images + imageName;
  }

  static String getConfigurationImagePath(String imageName) {
    return AssetsPaths.configurationImages + imageName;
  }

  static String _getAssetPath(String assetName) {
    return AssetsPaths.assets + assetName;
  }
}
