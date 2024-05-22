import 'package:fluffychat/presentation/mixins/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:fluffychat/presentation/mixins/go_to_group_chat_mixin.dart';
import 'package:fluffychat/presentation/mixins/invite_external_contact_mixin.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:fluffychat/presentation/mixins/go_to_direct_chat_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NewPrivateChat extends StatefulWidget {
  const NewPrivateChat({super.key});

  @override
  NewPrivateChatController createState() => NewPrivateChatController();
}

class NewPrivateChatController extends State<NewPrivateChat>
    with
        ComparablePresentationContactMixin,
        ContactsViewControllerMixin,
        GoToDraftChatMixin,
        InviteExternalContactMixin,
        GoToGroupChatMixin {
  final isShowContactsNotifier = ValueNotifier(true);
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        initialFetchContacts(
          client: Matrix.of(context).client,
          matrixLocalizations: MatrixLocals(L10n.of(context)!),
        );
      }
    });
    // FIXME: Find out solution for disable load more in search
    // searchContactsController.onSearchKeywordChanged = (searchKey) {
    //   disableLoadMoreInSearch();
    // };
  }

  void toggleContactsList() {
    isShowContactsNotifier.value = !isShowContactsNotifier.value;
  }

  void onContactAction(
    BuildContext context,
    PresentationContact contact,
  ) async {
    final roomId =
        Matrix.of(context).client.getDirectChatFromUserId(contact.matrixId!);
    if (roomId == null) {
      goToDraftChat(
        context: context,
        path: 'rooms',
        contactPresentationSearch: ContactPresentationSearch(
          matrixId: contact.matrixId,
          email: contact.email,
          displayName: contact.displayName,
        ),
      );
    } else {
      context.push('/rooms/$roomId');
    }
  }

  void onExternalContactAction(
    BuildContext context,
    PresentationContact contact,
  ) {
    showInviteExternalContactDialog(context, () {
      onContactAction(
        context,
        contact,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    disposeContactsMixin();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) => NewPrivateChatView(this);
}
