import 'package:fluffychat/resource/assets_paths.dart';

class ImagePaths {
  static String get bannerEmptyChat => _getImagePath('banner_empty_chat.svg');
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
  static String get icMute => _getImagePath('ic_mute.svg');
  static String get icPin => _getImagePath('ic_pin.svg');
  static String get icAddPeople => _getImagePath('ic_add_people.svg');
  static String get icEdit => _getImagePath('ic_edit.svg');
  static String get icMessages => _getImagePath('ic_messages.svg');
  static String get icRectangleInfo => _getImagePath('ic_rectangle_info.svg');
  static String get icChannels => _getImagePath('ic_channels.svg');

  static String _getImagePath(String imageName) {
    return AssetsPaths.images + imageName;
  }
}
