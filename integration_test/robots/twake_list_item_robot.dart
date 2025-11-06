import 'package:fluffychat/pages/chat/events/event_video_player.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/chat/events/message_download_content.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/widgets/file_widget/base_file_tile_widget.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class TwakeListItemRobot extends CoreRobot {
  final PatrolFinder root;
  TwakeListItemRobot(super.$, this.root);

  Future<PatrolFinder> getRadiobtn() async {
    return root.$(Radio).at(0);
  }

  Future<PatrolFinder> getCheckBox() async {
    return root.$(Checkbox).at(0);
  }
  
  PatrolFinder getTitle() {
    return root.$(ChatListItemTitle).$(Text).at(0);
  }

  Future<PatrolFinder> getOwnerLabel() async {
    return root.$(Text).containing('Owner');
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

  PatrolFinder getSentFileName() {
    return root.$(MessageDownloadContent).$(FileNameText).$(RichText);
  }

  PatrolFinder getImage() {
    return root.$(MessageContent).$(Image);
  }

  PatrolFinder getVideoDownloadIcon() {
    return root.$(MessageContent).$(CenterVideoButton);
  }
  
  int getUnreadMessage(){
    final animated = find.descendant(
      of: root,
      matching: find.byType(AnimatedContainer),
    );
    if(animated.evaluate().isNotEmpty) 
      { 
        final raw = root.$(ChatListItemSubtitle).$(Text).last.text; // String?
        final s = (raw ?? '').trim();
        final n = int.tryParse(s);
        return n ?? 0;
      }
    else {return 0;}
  }
}
