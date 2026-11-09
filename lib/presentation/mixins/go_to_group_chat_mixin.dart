import 'package:twake_chat/config/first_column_inner_routes.dart';
import 'package:twake_chat/utils/extension/build_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';

mixin GoToGroupChatMixin {
  void goToNewGroupChat(BuildContext context, {String? parentSpaceId}) {
    if (!FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
      context.pushInner('innernavigator/newgroup', arguments: parentSpaceId);
    } else {
      NewPrivateChatNewGroupRoute(parent: parentSpaceId).push(context);
    }
  }

  void goToNewSpace(BuildContext context, {String? parentSpaceId}) {
    if (!FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
      context.pushInner('innernavigator/newspace', arguments: parentSpaceId);
    } else {
      NewPrivateChatNewSpaceRoute(parent: parentSpaceId).push(context);
    }
  }

  void goToNewFeed(BuildContext context) {
    if (!FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
      context.pushInner('innernavigator/newfeed');
    } else {
      const NewPrivateChatNewFeedRoute().push(context);
    }
  }
}
