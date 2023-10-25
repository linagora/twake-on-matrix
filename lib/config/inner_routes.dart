import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/material.dart';

class InnerRoutes {
  InnerRoutes._();

  static final GlobalKey<NavigatorState> innerNavigatorOneColumnKey = GlobalKey(
    debugLabel: 'innerNavigatorGlobalKey',
  );

  static final GlobalKey<NavigatorState> innerNavigatorTwoColumnKey = GlobalKey(
    debugLabel: 'innerNavigatorTwoColumnKey',
  );

  static Route<dynamic> routes(String? routerName, {Object? arguments}) {
    switch (routerName) {
      case 'innernavigator/search':
        return _defaultPageRoute(
          const Search(),
        );
      case 'innernavigator/newgroup':
        return _defaultPageRoute(
          const NewGroup(),
        );
      case 'innernavigator/newprivatechat':
        return _defaultPageRoute(
          const NewPrivateChat(),
        );
      case 'innernavigator/newgroupchatinfo':
        if (arguments is Set<PresentationContact>) {
          return _defaultPageRoute(
            NewGroupChatInfo(
              contactsList: arguments,
            ),
          );
        } else {
          return _defaultPageRoute(const NewGroupChatInfo(contactsList: {}));
        }
      default:
        return _defaultPageRoute(const SizedBox.shrink());
    }
  }

  static PageRoute<dynamic> _defaultPageRoute(Widget widget) {
    return MaterialPageRoute(
      builder: (context) {
        return widget;
      },
    );
  }
}
