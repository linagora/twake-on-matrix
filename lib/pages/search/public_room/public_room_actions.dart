import 'package:fluffychat/pages/search/public_room/search_public_room_view_style.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';

enum PublicRoomActions {
  join,
  view;

  String getLabel(BuildContext context) {
    switch (this) {
      case PublicRoomActions.join:
        return L10n.of(context)!.joinRoom;
      case PublicRoomActions.view:
        return L10n.of(context)!.viewRoom;
    }
  }

  TextStyle? getLabelStyle(BuildContext context) {
    switch (this) {
      case PublicRoomActions.join:
        return SearchPublicRoomViewStyle.joinButtonLabelStyle(context);
      case PublicRoomActions.view:
        return SearchPublicRoomViewStyle.viewButtonLabelStyle(context);
    }
  }
}
