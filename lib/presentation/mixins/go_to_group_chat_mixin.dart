import 'package:fluffychat/config/first_column_inner_routes.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

mixin GoToGroupChatMixin {
  void goToNewGroupChat(BuildContext context) {
    if (!FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
      context.pushInner('innernavigator/newgroup');
    } else {
      context.push('/rooms/newprivatechat/newgroup');
    }
  }
}
