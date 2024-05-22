import 'package:fluffychat/config/first_column_inner_routes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/new_group/contacts_selection.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

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
      context.push(
        '/rooms/newprivatechat/newgroup/newgroupinfo',
        extra: contactsList.toSet(),
      );
    }
  }
}
