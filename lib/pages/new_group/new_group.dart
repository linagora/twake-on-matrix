import 'package:twake_chat/config/first_column_inner_routes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/pages/new_group/contacts_selection.dart';
import 'package:twake_chat/utils/extension/build_context_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';

class NewGroup extends StatefulWidget {
  const NewGroup({super.key});

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends ContactsSelectionController<NewGroup> {
  final responsiveUtils = getIt.get<ResponsiveUtils>();

  @override
  String getTitle(BuildContext context) {
    return L10n.of(context)!.addMembers;
  }

  @override
  String getHintText(BuildContext context) {
    return L10n.of(context)!.whoWouldYouLikeToAdd;
  }

  @override
  void onSubmit() {
    moveToNewGroupInfoScreen();
  }

  void moveToNewGroupInfoScreen() async {
    if (!FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
      context.pushInner(
        'innernavigator/newgroupchatinfo',
        arguments: contactsList.toSet(),
      );
    } else {
      NewPrivateChatNewGroupInfoRoute(
        $extra: contactsList.toSet(),
      ).push(context);
    }
  }
}
