import 'package:twake_chat/pages/new_group/new_group.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';
import 'package:twake_chat/pages/new_private_chat/new_private_chat.dart';
import 'package:twake_chat/pages/search/search.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/twake_cupertino_page.dart';
import 'package:flutter/cupertino.dart';

/// What the group info screen receives from the contacts selection.
class NewGroupInfoArguments {
  const NewGroupInfoArguments(this.contacts, {this.parentSpaceId});

  final Set<PresentationContact> contacts;
  final String? parentSpaceId;
}

class FirstColumnInnerRoutes {
  static final _firstColumnInnerRoutes = FirstColumnInnerRoutes._();

  FirstColumnInnerRoutes._();

  static FirstColumnInnerRoutes get instance => _firstColumnInnerRoutes;

  static final GlobalKey<NavigatorState> innerNavigatorOneColumnKey = GlobalKey(
    debugLabel: 'innerNavigatorGlobalKey',
  );

  static final GlobalKey<NavigatorState> innerNavigatorNotOneColumnKey =
      GlobalKey(debugLabel: 'innerNavigatorNotOneColumnKey');

  static Route<dynamic> routes(String? routerName, {Object? arguments}) {
    switch (routerName) {
      case 'innernavigator/search':
        return PageRouteBuilder(pageBuilder: (_, __, ___) => const Search());
      case 'innernavigator/newgroup':
        return _defaultPageRoute(
          NewGroup(parentSpaceId: arguments is String ? arguments : null),
        );
      case 'innernavigator/newprivatechat':
        return _defaultPageRoute(const NewPrivateChat());
      case 'innernavigator/newgroupchatinfo':
        return _infoRoute(NewGroupKind.group, arguments);
      case 'innernavigator/newfeed':
        return _defaultPageRoute(const NewGroup(kind: NewGroupKind.feed));
      case 'innernavigator/newfeedinfo':
        return _infoRoute(NewGroupKind.feed, arguments);
      case 'innernavigator/newspace':
        return _defaultPageRoute(
          NewGroup(
            kind: NewGroupKind.space,
            parentSpaceId: arguments is String ? arguments : null,
          ),
        );
      case 'innernavigator/newspaceinfo':
        return _infoRoute(NewGroupKind.space, arguments);
      default:
        return _defaultPageRoute(const SizedBox.shrink());
    }
  }

  static PageRoute<dynamic> _infoRoute(NewGroupKind kind, Object? arguments) {
    final info = arguments is NewGroupInfoArguments ? arguments : null;
    return _defaultPageRoute(
      NewGroupChatInfo(
        contactsList: info?.contacts ?? const {},
        kind: kind,
        parentSpaceId: info?.parentSpaceId,
      ),
    );
  }

  /// The navigator of the chat list column, whichever pane asks: the new group
  /// flow opens there, as from the button of the list.
  BuildContext innerContextFrom(BuildContext context) =>
      innerNavigatorNotOneColumnKey.currentContext ??
      innerNavigatorOneColumnKey.currentContext ??
      context;

  static PageRoute<dynamic> _defaultPageRoute(Widget widget) {
    return TwakeCupertinoPageRoute(
      builder: (context) {
        return widget;
      },
    );
  }

  bool goRouteAvailableInFirstColumn() {
    return PlatformInfos.isMobile;
  }
}
