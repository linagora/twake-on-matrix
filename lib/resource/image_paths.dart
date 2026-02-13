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
  static String get icSearchEmojiEmpty =>
      _getImagePath('search_emoji_empty.svg');

  static String get icShieldLockFill =>
      _getImagePath('ic_shield_lock_fill.svg');

  static String get icBrandingPng => _getAssetPath('branding.png');
  static String get lottieChat => _getAssetPath('lottie-chat.json');
  static String get icGhost => _getImagePath('ic_ghost.svg');
  static String get icChatError => _getImagePath('ic_chat_error.svg');
  static String get icRadioChecked => _getImagePath('ic_radio_checked.svg');
  static String get icRadioUnchecked => _getImagePath('ic_radio_unchecked.svg');
  static String get icFrontHand => _getImagePath('ic_front_hand.svg');
  static String get icRecorder => _getImagePath('ic_recorder.svg');
  static String get icTimeRecorderWeb =>
      _getImagePath('ic_time_recorder_web.svg');
  static String get icDeleteRecorderWeb =>
      _getImagePath('ic_delete_recorder_web.svg');

  static String get icAudioSpeed1x => _getImagePath('audio_speed_1x.svg');

  static String get icAudioSpeed1_5x => _getImagePath('audio_speed_1_5x.svg');

  static String get icAudioSpeed2x => _getImagePath('audio_speed_2x.svg');

  static String get icAudioSpeed0_5x => _getImagePath('audio_speed_0_5x.svg');

  static String get supportAvatarPng => _getAssetPath('support_avatar.png');
  static String get supportWelcome => _getImagePath('support_welcome.svg');

  static String get icE2EEncryptionMessageIndicator =>
      _getImagePath('ic_end_to_end_encryption_message_indicator.svg');

  static String get personalQrBackground =>
      _getAssetPath('personal_qr_background.png');

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
