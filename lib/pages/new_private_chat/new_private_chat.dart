import 'package:fluffychat/presentation/mixins/address_book_mixin.dart';
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
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

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
        WidgetsBindingObserver,
        InviteExternalContactMixin,
        AddressBooksMixin,
        GoToGroupChatMixin {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      WidgetsBinding.instance.addObserver(this);
      if (mounted) {
        final client = Matrix.of(context).client;
        listenAddressBookEvents(client);
        initialFetchContacts(
          context: context,
          client: client,
          matrixLocalizations: MatrixLocals(L10n.of(context)!),
        );
      }
    });
    // FIXME: Find out solution for disable load more in search
    // searchContactsController.onSearchKeywordChanged = (searchKey) {
    //   disableLoadMoreInSearch();
    // };
  }

  void onContactAction(
    BuildContext context,
    PresentationContact contact,
  ) async {
    if (contact.matrixId == null || contact.matrixId?.isEmpty == true) {
      Logs().e('NewPrivateChatController::onContactAction: no MatrixId');
      return;
    }
    final roomId =
        Matrix.of(context).client.getDirectChatFromUserId(contact.matrixId!);
    final room =
        roomId != null ? Matrix.of(context).client.getRoomById(roomId) : null;
    if (roomId == null || room?.isAbandonedDMRoom == true) {
      goToDraftChat(
        context: context,
        path: 'rooms',
        contactPresentationSearch: ContactPresentationSearch(
          matrixId: contact.matrixId,
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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await handleDidChangeAppLifecycleState(
      state,
      client: Matrix.of(context).client,
    );
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    disposeContactsMixin();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) => NewPrivateChatView(this);
}
