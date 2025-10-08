import 'package:fluffychat/pages/chat_list/chat_custom_slidable_action.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class TwakeListItemRobot extends CoreRobot {
  final PatrolFinder root;
  TwakeListItemRobot(super.$, this.root);

  Future<PatrolFinder> getRadiobtn() async {
    return root.$(Radio).at(0);
  }

  PatrolFinder getCheckBox() {
    return root.$(Checkbox);
  }
  
  PatrolFinder getTitle() {
    return root.$(ChatListItemTitle).$(Text).at(0);
  }

  Future<PatrolFinder> getOwnerLabel() async {
    return root.$(Text).containing('Owner');
  }

  PatrolFinder getNumberUnReadIcon() {
    return root.$(ChatListItemSubtitle).$(AnimatedContainer).containing($(Text));
  }

  PatrolFinder getUnreadBtn() {
    const icon = IconData(0xF1B4, fontFamily: 'MaterialIcons');
    return $(ChatCustomSlidableAction).containing(find.byIcon(icon));
  }

  PatrolFinder getReadBtn() {
    const icon = IconData(0xF1B3, fontFamily: 'MaterialIcons');
    return $(ChatCustomSlidableAction).containing(find.byIcon(icon));
  }

  PatrolFinder getMuteBtn() {
    const icon = IconData(0xF236, fontFamily: 'MaterialIcons');
    return $(ChatCustomSlidableAction).containing(find.byIcon(icon));
  }

  PatrolFinder getUnmuteBtn() {
    const icon = IconData(0xF234, fontFamily: 'MaterialIcons');
    return $(ChatCustomSlidableAction).containing(find.byIcon(icon));
  }

  PatrolFinder getPinBtn() {
    const icon = IconData(0xF2D7, fontFamily: 'MaterialIcons');
    return $(ChatCustomSlidableAction).containing(find.byIcon(icon));
  }

  PatrolFinder getUnpinBtn() {
    // return $(ChatCustomSlidableAction).containing($(SvgPicture));
    final unpinSvg = find.byWidgetPredicate((w) {
    if (w is SvgPicture) {
      final loader = w.bytesLoader;
      return loader is SvgAssetLoader &&
            loader.assetName == 'assets/images/ic_unpin.svg';
    }
    return false;
    });
    return $(unpinSvg);
  }

  PatrolFinder getHaveNotReadMessageReadIcon() {

    const iconData = IconData(0xE1F7, fontFamily: 'MaterialIcons');
    const wantColor  = Color(0xFF5C9CE6); // #5c9ce6

    final finder = find.descendant(
      of: root.$(ChatListItemSubtitle),
      matching: find.byElementPredicate(
        (el) {
          final w = el.widget;
          if (w is Icon && w.icon == iconData) {
            // Get actual color: priority to w.color, if null then get color from IconTheme
            final Color? actual =
                w.color ?? IconTheme.of(el).color;
            return actual?.value == wantColor.value;
          }
          return false;
        },
        description:
            'Icon U+E1F7 has color #5c9ce6 trong ChatListItemSubtitle',
      ),
    );
    return $(finder);  
  }

  PatrolFinder getAlreadyReadMessageReadIcon() {
    const iconData = IconData(0xE1F7, fontFamily: 'MaterialIcons');
    const wantColor  = Color(0xFF99A0A9); // #99A0A9

    final finder = find.descendant(
      of: root.$(ChatListItemSubtitle),
      matching: find.byElementPredicate(
        (el) {
          final w = el.widget;
          if (w is Icon && w.icon == iconData) {
            // Get actual color: priority to w.color, if null then get color from IconTheme
            final Color? actual =
                w.color ?? IconTheme.of(el).color;
            return actual?.value == wantColor.value;
          }
          return false;
        },
        description:
            'Icon U+E1F7 has color #99A0A9 in ChatListItemSubtitle',
      ),
    );
    return $(finder);
  }
  
  PatrolFinder getUnReadIcon() {
    // if(root.$(AnimatedContainer).evaluate().length >1)
    // {return root.$(AnimatedContainer).last;}
    
    // return getNumberUnReadIcon();  
    const target = Color(0xFF0A84FF); // #0a84ff, viết hoa/thường đều OK

    return root.$(ChatListItemSubtitle).$(
      find.byWidgetPredicate(
        (w) {
          // AnimatedContainer: màu nằm trong decoration
          if (w is AnimatedContainer) {
            final d = w.decoration;
            if (d is BoxDecoration && d.color?.value == target.value) return true;
          }

          return false;
        },
        description: 'Any box with background #0A48FF',
      ),
    );
  }

  PatrolFinder getPinIcon(){
    final title = root.$(ChatListItemTitle);
    const pinData = IconData(0xF2D7, fontFamily: 'MaterialIcons');
    final pinFinder = find.descendant(of: title, matching: find.byIcon(pinData));
    return $(pinFinder);
  }

  PatrolFinder getMutedIcon(){
    final title = root.$(ChatListItemTitle);
    const pinData = IconData(0xF4A7, fontFamily: 'MaterialIcons');
    return $(find.descendant(of: title, matching: find.byIcon(pinData)));
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

  int getUnreadMessage(){
    final animated = find.descendant(
      of: root,
      matching: find.byType(AnimatedContainer),
    );
    if(animated.evaluate().isNotEmpty) 
      { 
        final raw = getNumberUnReadIcon().$(Text).text; // String?
        final s = (raw ?? '').trim();
        final n = int.tryParse(s);
        return n ?? 0;
      }
    else {return 0;}
  }

  Future<void> mute() async {
    await getMuteBtn().tap();
    await $.waitUntilVisible(getMutedIcon());
  }

  Future<void> unmute() async {
    await getUnmuteBtn().tap();
    await $.waitUntilVisible(getTitle());
  }

  Future<void> pin() async {
    await getPinBtn().tap();
    await $.waitUntilVisible(getPinIcon());
  }

  Future<void> unpin() async {
    await getUnpinBtn().tap();
    await $.waitUntilVisible(getTitle());
  }

  Future<void> read() async {
    await getReadBtn().tap();
    await $.waitUntilVisible(getTitle());
  }

  Future<void> unread() async {
    await getUnreadBtn().tap();
    await $.waitUntilVisible(getTitle());
  }
}
