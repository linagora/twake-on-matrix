import 'package:fluffychat/base/base_controller.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view.dart';
import 'package:fluffychat/presentation/mixin/go_to_direct_chat_mixin.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:matrix/matrix.dart';

class ContactsTab extends StatefulWidget {

  const ContactsTab({super.key});

  @override
  State<StatefulWidget> createState() => ContactsTabController();

}

class ContactsTabController extends State<ContactsTab> 
  with ComparablePresentationContactMixin, GoToDirectChatMixin, BaseController {

  final searchContactsController = SearchContactsController();
  final fetchContactsController = FetchContactsController();

  @override
  initState() {
    searchContactsController.init();
    _listenFocusTextEditing();
    listenContactsStartList();
    listenSearchContacts();
    super.initState();
    fetchContactsController.fetchCurrentTomContacts();
    fetchContactsController.listenForScrollChanged(fetchContactsController: fetchContactsController);
    searchContactsController.onSearchKeywordChanged = (searchKey) {
      disableLoadMoreInSearch();
    };
  }

  void disableLoadMoreInSearch() {
    fetchContactsController.allowLoadMore = searchContactsController.searchKeyword.isEmpty;
  }

  void listenContactsStartList() {
    fetchContactsController.streamController.stream.listen((event) {
      Logs().d('NewPrivateChatController::fetchContacts() - event: $event');
      streamController.add(event);
    });
  }

  void listenSearchContacts() {
    searchContactsController.lookupStreamController.stream.listen((event) {
      Logs().d('NewPrivateChatController::_fetchRemoteContacts() - event: $event');
      streamController.add(event);
    });
  }

  void _listenFocusTextEditing() {
    searchContactsController.searchFocusNode.addListener(() {
      searchContactsController.isSearchModeNotifier.value = searchContactsController.searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    searchContactsController.dispose();
    fetchContactsController.dispose();
    streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ContactsTabView(contactsController: this);
}