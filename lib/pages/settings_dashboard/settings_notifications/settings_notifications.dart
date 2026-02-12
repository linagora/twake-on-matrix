import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:fluffychat/generated/l10n/app_localizations.dart';

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
  bool? getNotificationSetting(NotificationSettingsItem item) {
    final pushRules = Matrix.of(context).client.globalPushRules;
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
        final client = Matrix.of(context).client;
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
      future: () => Matrix.of(context).client.deletePusher(
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
