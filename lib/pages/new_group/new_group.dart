import 'package:twake_chat/config/first_column_inner_routes.dart';
import 'package:twake_chat/pages/new_group/contacts_selection.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';
import 'package:twake_chat/utils/extension/build_context_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';

class NewGroup extends ConsumerStatefulWidget {
  final NewGroupKind kind;

  /// The space the flow was opened from, chosen beforehand.
  final String? parentSpaceId;

  const NewGroup({
    super.key,
    this.kind = NewGroupKind.group,
    this.parentSpaceId,
  });

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends ContactsSelectionController<NewGroup> {
  final responsiveUtils = ResponsiveUtils();

  @override
  String getTitle(BuildContext context) {
    return L10n.of(context)!.addMembers;
  }

  @override
  String getHintText(BuildContext context) {
    return L10n.of(context)!.whoWouldYouLikeToAdd;
  }

  @override
  bool get isSelectionRequired =>
      widget.kind.isMemberRequired(parentSpaceId: widget.parentSpaceId);

  @override
  void onSubmit() {
    moveToNewGroupInfoScreen();
  }

  void moveToNewGroupInfoScreen() async {
    final contacts = contactsList.toSet();
    final parent = widget.parentSpaceId;
    if (!FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
      context.pushInner(switch (widget.kind) {
        NewGroupKind.feed => 'innernavigator/newfeedinfo',
        NewGroupKind.space => 'innernavigator/newspaceinfo',
        NewGroupKind.group => 'innernavigator/newgroupchatinfo',
      }, arguments: NewGroupInfoArguments(contacts, parentSpaceId: parent));
      return;
    }
    switch (widget.kind) {
      case NewGroupKind.feed:
        NewPrivateChatNewFeedInfoRoute($extra: contacts).push(context);
      case NewGroupKind.space:
        NewPrivateChatNewSpaceInfoRoute(
          parent: parent,
          $extra: contacts,
        ).push(context);
      case NewGroupKind.group:
        NewPrivateChatNewGroupInfoRoute(
          parent: parent,
          $extra: contacts,
        ).push(context);
    }
  }
}
