abstract class SettingKeys {
  static const String wallpaper = 'chat.twake.wallpaper';
  static const String renderHtml = 'chat.twake.renderHtml';
  static const String hideUnknownEvents = 'chat.twake.hideUnknownEvents';
  static const String hideUnimportantStateEvents =
      'chat.twake.hideUnimportantStateEvents';
  static const String showDirectChatsInSpaces =
      'chat.twake.showDirectChatsInSpaces';
  static const String separateChatTypes = 'chat.twake.separateChatTypes';
  static const String sentry = 'sentry';
  static const String theme = 'theme';
  static const String amoledEnabled = 'amoled_enabled';
  static const String codeLanguage = 'code_language';
  static const String showNoGoogle = 'chat.twake.show_no_google';
  static const String bubbleSizeFactor = 'chat.twake.bubble_size_factor';
  static const String fontSizeFactor = 'chat.twake.font_size_factor';
  static const String showNoPid = 'chat.twake.show_no_pid';
  static const String databasePassword = 'database-password';
  static const String appLockKey = 'chat.twake.app_lock';
  static const String unifiedPushRegistered =
      'chat.twake.unifiedpush.registered';
  static const String unifiedPushEndpoint = 'chat.twake.unifiedpush.endpoint';
  static const String notificationCurrentIds = 'chat.twake.notification_ids';
  static const String ownStatusMessage = 'chat.twake.status_msg';
  static const String dontAskForBootstrapKey = 'chat.twake.dont_ask_bootstrap';
  static const String autoplayImages = 'chat.twake.autoplay_images';
  static const String experimentalVoip = 'chat.twake.experimental_voip';
  static const String enableRightAndLeftMessageAlignmentOnWeb =
      'chat.twake.enable_right_and_left_message_alignment_on_web';
  static const String gifAutoplay = 'chat.twake.gif_autoplay';
}

/// Maps each current [SettingKeys] value to its legacy `chat.fluffy.*` (or
/// `chat.fluffychat.*`) equivalent, for one-time migration on app startup.
///
/// See `lib/utils/manager/legacy_settings_migration_manager.dart`.
const Map<String, String> legacySettingKeys = {
  SettingKeys.wallpaper: 'chat.fluffy.wallpaper',
  SettingKeys.renderHtml: 'chat.fluffy.renderHtml',
  SettingKeys.hideUnknownEvents: 'chat.fluffy.hideUnknownEvents',
  SettingKeys.hideUnimportantStateEvents:
      'chat.fluffy.hideUnimportantStateEvents',
  SettingKeys.showDirectChatsInSpaces: 'chat.fluffy.showDirectChatsInSpaces',
  SettingKeys.separateChatTypes: 'chat.fluffy.separateChatTypes',
  SettingKeys.showNoGoogle: 'chat.fluffy.show_no_google',
  SettingKeys.bubbleSizeFactor: 'chat.fluffy.bubble_size_factor',
  SettingKeys.fontSizeFactor: 'chat.fluffy.font_size_factor',
  SettingKeys.showNoPid: 'chat.fluffy.show_no_pid',
  SettingKeys.unifiedPushRegistered: 'chat.fluffy.unifiedpush.registered',
  SettingKeys.unifiedPushEndpoint: 'chat.fluffy.unifiedpush.endpoint',
  SettingKeys.notificationCurrentIds: 'chat.fluffy.notification_ids',
  SettingKeys.ownStatusMessage: 'chat.fluffy.status_msg',
  SettingKeys.dontAskForBootstrapKey: 'chat.fluffychat.dont_ask_bootstrap',
  SettingKeys.autoplayImages: 'chat.fluffy.autoplay_images',
  SettingKeys.experimentalVoip: 'chat.fluffy.experimental_voip',
};

/// Legacy key for [SettingKeys.appLockKey], migrated separately since it
/// lives in secure storage (or SharedPreferences on Linux) rather than the
/// plain string/bool/int keys in [legacySettingKeys].
const String legacyAppLockKey = 'chat.fluffy.app_lock';
