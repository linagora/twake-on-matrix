import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:twake_chat/presentation/mixins/connect_page_mixin.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/web_push/web_push.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:twake_chat/generated/l10n/app_localizations.dart';

import 'package:matrix/matrix.dart';

import 'settings_notifications_view.dart';

enum PushRule {
  roomOneToOne(ruleKey: '.m.rule.room_one_to_one'),
  roomEncryptedOneToOne(ruleKey: '.m.rule.encrypted_room_one_to_one'),
  containsDisplayName(ruleKey: '.m.rule.contains_display_name'),
  containsUserName(ruleKey: '.m.rule.contains_user_name'),
  inviteForMe(ruleKey: '.m.rule.invite_for_me'),
  memberEvent(ruleKey: '.m.rule.member_event'),
  suppressNotices(ruleKey: '.m.rule.suppress_notices');

  const PushRule({required this.ruleKey});

  final String ruleKey;

  String getRuleTitle(L10n l10n) {
    switch (this) {
      case PushRule.roomOneToOne:
      case PushRule.roomEncryptedOneToOne:
        return l10n.directChats;
      case PushRule.containsDisplayName:
        return l10n.containsDisplayName;
      case PushRule.containsUserName:
        return l10n.containsUserName;
      case PushRule.inviteForMe:
        return l10n.inviteForMe;
      case PushRule.memberEvent:
        return l10n.memberChanges;
      case PushRule.suppressNotices:
        return l10n.botMessages;
    }
  }
}

class NotificationSettingsItem {
  final PushRuleKind type;
  final String key;
  final String Function(BuildContext) title;
  const NotificationSettingsItem(this.type, this.key, this.title);
  static List<NotificationSettingsItem> items = [
    NotificationSettingsItem(
      PushRuleKind.underride,
      PushRule.roomOneToOne.ruleKey,
      (c) => PushRule.roomOneToOne.getRuleTitle(L10n.of(c)!),
    ),
    NotificationSettingsItem(
      PushRuleKind.override,
      PushRule.containsDisplayName.ruleKey,
      (c) => PushRule.containsDisplayName.getRuleTitle(L10n.of(c)!),
    ),
    NotificationSettingsItem(
      PushRuleKind.content,
      PushRule.containsUserName.ruleKey,
      (c) => PushRule.containsUserName.getRuleTitle(L10n.of(c)!),
    ),
    NotificationSettingsItem(
      PushRuleKind.override,
      PushRule.inviteForMe.ruleKey,
      (c) => PushRule.inviteForMe.getRuleTitle(L10n.of(c)!),
    ),
    NotificationSettingsItem(
      PushRuleKind.override,
      PushRule.memberEvent.ruleKey,
      (c) => PushRule.memberEvent.getRuleTitle(L10n.of(c)!),
    ),
    NotificationSettingsItem(
      PushRuleKind.override,
      PushRule.suppressNotices.ruleKey,
      (c) => PushRule.suppressNotices.getRuleTitle(L10n.of(c)!),
    ),
  ];
}

class SettingsNotifications extends StatefulWidget {
  const SettingsNotifications({super.key});

  @override
  SettingsNotificationsController createState() =>
      SettingsNotificationsController();
}

class SettingsNotificationsController extends State<SettingsNotifications> {
  /// Web Push on this browser. null while loading; web-only.
  bool? webPushActive;
  bool webPushPermissionDenied = false;

  Client get _client => Matrix.of(context).client;

  bool get showWebPushTile => kIsWeb && AppConfig.webPushEnabled;

  /// Encrypted previews on iOS: the notification extension gets its own
  /// device through a second SSO login. null while loading or unsupported.
  bool? encryptedPreviewsActive;
  String? _ssoProviderId;

  /// The app cross-signs the extension's device, so it needs the
  /// self-signing key in cache.
  bool encryptedPreviewsLocked = false;

  bool get showEncryptedPreviewsTile =>
      PlatformInfos.isIOS && _ssoProviderId != null;

  @override
  void initState() {
    super.initState();
    if (showWebPushTile) _loadWebPushStatus();
    if (PlatformInfos.isIOS) _loadEncryptedPreviewsStatus();
  }

  Future<void> _loadEncryptedPreviewsStatus() async {
    final client = _client;
    _ssoProviderId = await KeychainSharingManager.notificationSsoProviderId(
      client,
    );
    final active = await KeychainSharingManager.hasNotificationSession(client);
    final cached = await client.encryption?.crossSigning.isCached() ?? false;
    // Without cross-signing, senders share keys with every device anyway.
    final hasMasterKey =
        client.userDeviceKeys[client.userID]?.masterKey != null;
    if (!mounted) return;
    setState(() {
      encryptedPreviewsActive = active;
      encryptedPreviewsLocked = hasMasterKey && !cached;
    });
  }

  Future<void> toggleEncryptedPreviews(bool enabled) async {
    final client = _client;
    final providerId = _ssoProviderId;
    final homeserver = client.homeserver;
    if (providerId == null || homeserver == null) return;
    if (enabled) {
      final String callback;
      try {
        callback = await ConnectPageMixin.webAuthenticate(
          homeserver: homeserver.toString(),
          id: providerId,
        );
      } catch (e) {
        Logs().w('SSO for encrypted previews cancelled', e);
        return;
      }
      final loginToken = Uri.parse(callback).queryParameters['loginToken'];
      if (loginToken == null || loginToken.isEmpty || !mounted) return;
      await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () => KeychainSharingManager.createNotificationSession(
          client,
          loginToken,
        ),
      );
    } else {
      await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () => KeychainSharingManager.logoutNotificationSession(client),
      );
    }
    if (!mounted) return;
    await _loadEncryptedPreviewsStatus();
  }

  Future<void> _loadWebPushStatus() async {
    final active = await isWebPushActive();
    if (!mounted) return;
    setState(() {
      webPushActive = active;
      webPushPermissionDenied = isWebPushPermissionDenied();
    });
  }

  /// Single place to enable/disable Web Push: persists the choice (so a disabled
  /// pusher stays gone) and (re)subscribes or tears down accordingly.
  Future<void> toggleWebPush(bool enabled) async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => setWebPushEnabled(_client, enabled),
    );
    await _loadWebPushStatus();
  }

  bool? getNotificationSetting(NotificationSettingsItem item) {
    final pushRules = _client.globalPushRules;
    if (pushRules == null) return null;

    if (item.key == PushRule.roomOneToOne.ruleKey) {
      return pushRules.underride
          ?.where((r) => r.ruleId == item.key)
          .any((r) => r.actions.isNotEmpty);
    }

    switch (item.type) {
      case PushRuleKind.content:
        return pushRules.content
            ?.singleWhereOrNull((r) => r.ruleId == item.key)
            ?.enabled;
      case PushRuleKind.override:
        return pushRules.override
            ?.singleWhereOrNull((r) => r.ruleId == item.key)
            ?.enabled;
      case PushRuleKind.room:
        return pushRules.room
            ?.singleWhereOrNull((r) => r.ruleId == item.key)
            ?.enabled;
      case PushRuleKind.sender:
        return pushRules.sender
            ?.singleWhereOrNull((r) => r.ruleId == item.key)
            ?.enabled;
      case PushRuleKind.underride:
        return pushRules.underride
            ?.singleWhereOrNull((r) => r.ruleId == item.key)
            ?.enabled;
    }
  }

  static const _oneToOneEnabledActions = [
    'notify',
    {"set_tweak": "sound", "value": "default"},
    {"set_tweak": "highlight", "value": false},
  ];

  void setNotificationSetting(NotificationSettingsItem item, bool enabled) {
    TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () {
        final client = _client;
        if (item.key == PushRule.roomOneToOne.ruleKey) {
          return Future.wait([
            client.setPushRuleEnabled(item.type, item.key, true),
            client.setPushRuleEnabled(
              item.type,
              PushRule.roomEncryptedOneToOne.ruleKey,
              true,
            ),
            client.setPushRuleActions(
              item.type,
              item.key,
              enabled ? _oneToOneEnabledActions : [],
            ),
            client.setPushRuleActions(
              item.type,
              PushRule.roomEncryptedOneToOne.ruleKey,
              enabled ? _oneToOneEnabledActions : [],
            ),
          ]);
        }

        return client.setPushRuleEnabled(item.type, item.key, enabled);
      },
    );
  }

  void onPusherTap(Pusher pusher) async {
    final delete = await showModalActionSheet<bool>(
      context: context,
      title: pusher.deviceDisplayName,
      message: '${pusher.appDisplayName} (${pusher.appId})',
      actions: [
        SheetAction(
          label: L10n.of(context)!.delete,
          isDestructiveAction: true,
          key: true,
        ),
      ],
    );
    if (delete != true) return;

    final success = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => _client.deletePusher(
        PusherId(appId: pusher.appId, pushkey: pusher.pushkey),
      ),
    );

    if (success.error != null) return;

    setState(() {
      pusherFuture = null;
    });
  }

  Future<List<Pusher>?>? pusherFuture;

  @override
  Widget build(BuildContext context) => SettingsNotificationsView(this);
}
