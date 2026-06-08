import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat_details/participant_list_item/participant_list_item.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class TwakeListItemRobot extends CoreRobot {
  final PatrolFinder root;

  TwakeListItemRobot(super.$, this.root);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).first))!;

  Future<PatrolFinder> getRadiobtn() async {
    return root.$(Radio).at(0);
  }

  PatrolFinder getCheckBox() {
    return root.$(Checkbox).at(0);
  }

  PatrolFinder getTitle() {
    return root.$(ChatListItemTitle).$(Text).at(0);
  }

  Future<PatrolFinder> getOwnerLabel() async {
    return root.$(Text).containing(_l10n.owner);
  }

  Future<PatrolFinder> getEmailLabelIncaseSearching() async {
    return root.$(HighlightText).$(Text).at(0);
  }

  Future<PatrolFinder> getEmailLabel() async {
    return root.$(ChatListItemSubtitle).$(Text).at(0);
  }

  Future<PatrolFinder> getContactLabel() async {
    return root.$(ChatListItemSubtitle).$(Text).at(1);
  }

  PatrolFinder getPinIcon() {
    final title = root.$(ChatListItemTitle);
    const pinData = IconData(0xF2D7, fontFamily: 'MaterialIcons');
    final pinFinder = find.descendant(
      of: title,
      matching: find.byIcon(pinData),
    );
    return $(pinFinder);
  }

  PatrolFinder getProfile({required String matrixID}) {
    return root
        .$(ParticipantListItem)
        .containing(find.byKey(ValueKey<String>(matrixID)));
  }

  int getUnreadMessage() {
    // The notification-count badge is the trailing `AnimatedContainer` in the
    // subtitle (the earlier one is the "@" mention badge). Read its `Text`
    // rather than `Text.last`, which on web resolves to the message preview
    // (and would mis-parse a numeric message body as the count).
    final badges = root.$(ChatListItemSubtitle).$(AnimatedContainer);
    if (badges.evaluate().isEmpty) return 0;
    final countText = badges.last.$(Text);
    if (!countText.exists) return 0;
    return int.tryParse((countText.text ?? '').trim()) ?? 0;
  }
}
