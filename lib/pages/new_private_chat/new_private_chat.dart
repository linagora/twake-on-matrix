import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:fluffychat/presentation/converters/presentation_contact_converter.dart';
import 'package:fluffychat/presentation/mixins/go_to_direct_chat_mixin.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/presentation_contact_success.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/dialog/warning_dialog.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class NewPrivateChat extends StatefulWidget {
  const NewPrivateChat({Key? key}) : super(key: key);

  @override
  NewPrivateChatController createState() => NewPrivateChatController();
}

class NewPrivateChatController extends State<NewPrivateChat>
    with
        ComparablePresentationContactMixin,
        GoToDraftChatMixin,
        SearchContactsController {
  final isShowContactsNotifier = ValueNotifier(true);
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initSearchContacts(converter: _NewPrivateContactConverter());
    // FIXME: Find out solution for disable load more in search
    // searchContactsController.onSearchKeywordChanged = (searchKey) {
    //   disableLoadMoreInSearch();
    // };
    scrollController.addLoadMoreListener(loadMoreContacts);
  }

  void toggleContactsList() {
    isShowContactsNotifier.value = !isShowContactsNotifier.value;
  }

  void goToNewGroupChat() {
    context.push('/rooms/newprivatechat/newgroup');
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
        path: 'rooms/newprivatechat',
        contactPresentationSearch: ContactPresentationSearch(
          contact.matrixId,
          contact.email,
          displayName: contact.displayName,
        ),
      );
    } else {
      context.go('/rooms/$roomId');
    }
  }

  void onExternalContactAction(
    BuildContext context,
    PresentationContact contact,
  ) {
    WarningDialog.showCancelable(
      context,
      title: L10n.of(context)?.externalContactTitle,
      message: L10n.of(context)?.externalContactMessage,
      acceptText: L10n.of(context)?.invite,
      cancelText: L10n.of(context)?.skip,
      onAccept: () {
        onContactAction(
          context,
          contact,
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    disposeSearchContacts();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) => NewPrivateChatView(this);
}

class _NewPrivateContactConverter extends PresentationContactConverter {
  @override
  Success convert(Success success) {
    final converted = super.convert(success);
    if (converted is PresentationContactsSuccess &&
        converted.data.isEmpty &&
        converted.keyword.isValidMatrixId &&
        converted.keyword.startsWith("@")) {
      return PresentationExternalContactSuccess(
        contact: PresentationContact(
          matrixId: converted.keyword,
          displayName: converted.keyword.substring(1),
          email: converted.keyword,
        ),
      );
    }
    return converted;
  }
}
