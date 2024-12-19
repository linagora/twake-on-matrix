import 'dart:async';
import 'dart:io';

import 'package:fluffychat/config/config_saas/config_saas.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:matrix/matrix.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

abstract class AppConfig {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static Completer<bool> initConfigCompleter = Completer<bool>();

  static int retryCompleterCount = 0;

  static bool get hasReachedMaxRetries => retryCompleterCount == 3;

  static String _applicationName = 'Twake Chat';

  static String get applicationName => _applicationName;
  static String? _applicationWelcomeMessage;

  static String? get applicationWelcomeMessage => _applicationWelcomeMessage;
  static String _defaultHomeserver = 'matrix.linagora.com';

  static String get defaultHomeserver => _defaultHomeserver;
  static double bubbleSizeFactor = 1;
  static double fontSizeFactor = 1;

  static const double messagePadding = 16.0;

  static String sampleValue = 'sampleValue';

  ///`REGISTRATION_URL`: Registration URL for public platform, sample is `https://example.com`
  static String registrationUrl = sampleValue;

  ///`TWAKE_WORKPLACE_HOMESERVER`: Twake workplace homeserver, sample is `https://example.com`
  static String twakeWorkplaceHomeserver = sampleValue;

  ///`HOME_SERVER`: Homeserver, sample is `https://example.com`
  static String homeserver = sampleValue;

  static String appParameter = 'chat';

  static String? platform;

  static String _appPolicy = 'https://twake.app/policy';

  static String appTermsOfUse = 'https://twake.app/terms';

  static String qrCodeDownloadUrl = 'https://sign-up.twake.app/download/chat';

  static String twakeChatAppleStore =
      'https://apps.apple.com/us/app/twake-chat/id6473384641';

  static String twakeChatGooglePlay =
      'https://play.google.com/store/apps/details?id=app.twake.android.chat';

  static double toolbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 48 : 56;
  static const Color chatColor = primaryColor;
  static Color colorSchemeSeed = primaryColor;
  static const double messageFontSize = 17.0;
  static const bool allowOtherHomeservers = true;
  static const bool enableRegistration = true;
  static const Color primaryColor = Color.fromARGB(255, 135, 103, 172);
  static const Color primaryColorLight = Color(0xFFCCBDEA);
  static const Color secondaryColor = Color(0xFF41a2bc);

  static String get privacyUrl => _appPolicy;
  static const String enablePushTutorial =
      'https://gitlab.com/famedly/fluffychat/-/wikis/Push-Notifications-without-Google-Services';
  static const String encryptionTutorial =
      'https://gitlab.com/famedly/fluffychat/-/wikis/How-to-use-end-to-end-encryption-in-FluffyChat';
  static const String appOpenUrlScheme = 'twake.chat';
  static String _webBaseUrl = 'https://fluffychat.im/web';

  static String get webBaseUrl => _webBaseUrl;
  static const String sourceCodeUrl =
      'https://github.com/linagora/twake-on-matrix';
  static String supportUrl = 'https://twake.app/support';
  static bool renderHtml = true;
  static bool hideRedactedEvents = false;
  static bool hideUnknownEvents = true;
  static bool hideUnimportantStateEvents = true;
  static bool showDirectChatsInSpaces = true;
  static bool separateChatTypes = false;
  static bool autoplayImages = true;
  static bool experimentalVoip = false;
  static bool appGridDashboardAvailable = true;
  static const bool hideTypingUsernames = false;
  static const bool hideAllStateEvents = false;
  static const String inviteLinkPrefix = 'https://matrix.to/#/';
  static const String deepLinkPrefix = 'im.fluffychat://chat/';
  static const String schemePrefix = 'matrix:';
  static const String pushNotificationsChannelId = 'twake_push';
  static const String pushNotificationsChannelName = 'Twake Chat push channel';
  static const String pushNotificationsChannelDescription =
      'Push notifications for Twake Chat';
  static String pushNotificationsAppId = Platform.isIOS
      ? kReleaseMode
          ? "app.twake.ios.chat"
          : "app.twake.ios.chat.sandbox"
      : "app.twake.android.chat";
  static const String pushNotificationsGatewayUrl =
      'https://sygnal.lin-saas.dev/_matrix/push/v1/notify';
  static const String pushNotificationsPusherFormat = 'event_id_only';
  static const String emojiFontName = 'Noto Emoji';
  static const String emojiFontUrl =
      'https://github.com/googlefonts/noto-emoji/';
  static const double borderRadius = 20.0;
  static const double columnWidth = 360.0;
  static const int maxFetchContacts = 100000;
  static const int chatRoomSearchKeywordMin = 2;
  static const bool chatRoomSearchWordStrategy = false;
  static const String defaultImageBlurHash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
  static const String defaultVideoBlurHash = 'L5H2EC=PM+yV0g-mq.wG9c010J}I';
  static const int thumbnailQuality = 70;
  static const int blurHashSize = 32;
  static const int imageQuality = 50;
  static const String iOSKeychainSharingId = 'KUT463DS29.app.twake.ios.chat';
  static const String iOSKeychainSharingAccount = 'app.twake.ios.chat.sessions';
  static const int maxFilesSendPerDialog = 6;
  static const bool supportMultipleAccountsInTheSameHomeserver = false;
  static const imageCompressFormmat = CompressFormat.jpeg;
  static const videoThumbnailFormat = ImageFormat.JPEG;

  static const List<String> allowedExtensionsSupportedAvatar = [
    'png',
    'jpg',
    'jpeg',
    'jfif',
  ];

  static String? issueId;

  static int defaultMaxUploadAvtarSizeInBytes = 10 * (1024 * 1024);

  static bool devMode = false;

  static const String appGridConfigurationPath =
      "configurations/app_dashboard.json";

  static const String _platformEnv = String.fromEnvironment(
    'PLATFORM',
    defaultValue: ConfigurationSaas.platform,
  );

  static const String _twakeWorkplaceHomeserverEnv = String.fromEnvironment(
    'TWAKE_WORKPLACE_HOMESERVER',
    defaultValue: ConfigurationSaas.twakeWorkplaceHomeserver,
  );

  static const String _registrationUrlEnv = String.fromEnvironment(
    'REGISTRATION_URL',
    defaultValue: ConfigurationSaas.registrationUrl,
  );

  static const String _homeserverEnv = String.fromEnvironment(
    'HOME_SERVER',
    defaultValue: ConfigurationSaas.homeserver,
  );

  static void loadEnvironment() {
    twakeWorkplaceHomeserver = _twakeWorkplaceHomeserverEnv;

    Logs().i(
      '[Public Platform] AppConfig():: TWAKE_WORKPLACE_HOMESERVER $_twakeWorkplaceHomeserverEnv',
    );

    registrationUrl = _registrationUrlEnv;

    Logs().i(
      '[Public Platform] AppConfig():: REGISTRATION_URL $_registrationUrlEnv',
    );

    platform = _platformEnv;

    Logs().i(
      '[Public Platform] AppConfig():: Platform $_platformEnv',
    );

    homeserver = _homeserverEnv;

    Logs().i(
      '[Public Platform] AppConfig():: HOME_SERVER $_homeserverEnv',
    );
  }

  static bool get isSaasPlatForm => _platformEnv == 'saas';

  static void loadFromJson(Map<String, dynamic> json) {
    if (json['homeserver'] != null && json['homeserver'] is String) {
      if (json['homeserver'] != '') {
        homeserver = json['homeserver'];
      }
    }

    if (json['registration_url'] != null &&
        json['registration_url'] is String) {
      if (json['registration_url'] != '') {
        registrationUrl = json['registration_url'];
      }
    }

    if (json['twake_workplace_homeserver'] != null &&
        json['twake_workplace_homeserver'] is String) {
      if (json['twake_workplace_homeserver'] != '') {
        twakeWorkplaceHomeserver = json['twake_workplace_homeserver'];
      }
    }

    if (json['chat_color'] != null) {
      try {
        colorSchemeSeed = Color(json['chat_color']);
      } catch (e) {
        Logs().w(
          'Invalid color in config.json! Please make sure to define the color in this format: "0xffdd0000"',
          e,
        );
      }
    }
    if (json['application_name'] is String) {
      _applicationName = json['application_name'];
    }
    if (json['application_welcome_message'] is String) {
      _applicationWelcomeMessage = json['application_welcome_message'];
    }
    if (json['default_homeserver'] is String) {
      _defaultHomeserver = json['default_homeserver'];
    }
    if (json['privacy_url'] is String) {
      _webBaseUrl = json['privacy_url'];
    }
    if (json['web_base_url'] is String) {
      _appPolicy = json['web_base_url'];
    }
    if (json['render_html'] is bool) {
      renderHtml = json['render_html'];
    }
    if (json['hide_redacted_events'] is bool) {
      hideRedactedEvents = json['hide_redacted_events'];
    }
    if (json['hide_unknown_events'] is bool) {
      hideUnknownEvents = json['hide_unknown_events'];
    }
    if (json['issue_id'] is String?) {
      issueId = json['issue_id'];
    }
    if (json['app_grid_dashboard_available'] is bool) {
      appGridDashboardAvailable = json['app_grid_dashboard_available'];
    }
    if (json['platform'] is String?) {
      platform = json['platform'];
    }
    if (json['default_max_upload_avatar_size_in_bytes'] is int) {
      defaultMaxUploadAvtarSizeInBytes =
          json['default_max_upload_avatar_size_in_bytes'];
    }
    if (json['dev_mode'] is bool) {
      devMode = json['dev_mode'];
    }
    if (json['qr_code_download_url'] is String) {
      qrCodeDownloadUrl = json['qr_code_download_url'];
    }
    if (json['enable_logs'] is bool) {
      DebugUtils.enableLogs = json['enable_logs'];
    }
    if (json['support_url'] is String) {
      supportUrl = json['support_url'];
    }
  }
}
