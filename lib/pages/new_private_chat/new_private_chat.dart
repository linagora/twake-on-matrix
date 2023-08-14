import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:fluffychat/presentation/mixins/go_to_direct_chat_mixin.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:go_router/go_router.dart';

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
    initSearchContacts();
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

  void onContactAction({
    required BuildContext context,
    required PresentationContact contact,
  }) {
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
      showFutureLoadingDialog(
        context: context,
        future: () async {
          if (contact.matrixId != null && contact.matrixId!.isNotEmpty) {
            context.go('/rooms/$roomId');
          }
        },
      );
    }
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
