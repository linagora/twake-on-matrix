import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view.dart';
import 'package:fluffychat/presentation/mixin/go_to_direct_chat_mixin.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:matrix/matrix.dart';
import 'package:rxdart/rxdart.dart';

class ContactsTab extends StatefulWidget {

  const ContactsTab({super.key});

  @override
  State<StatefulWidget> createState() => ContactsTabController();

}

class ContactsTabController extends State<ContactsTab> 
  with ComparablePresentationContactMixin, GoToDirectChatMixin {

  final searchContactsController = SearchContactsController();
  final fetchContactsController = FetchContactsController();
  final contactsStreamController = BehaviorSubject<Either<Failure, GetContactsSuccess>>();
  

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
      contactsStreamController.add(event);
    });
  }

  void listenSearchContacts() {
    searchContactsController.lookupStreamController.stream.listen((event) {
      Logs().d('NewPrivateChatController::_fetchRemoteContacts() - event: $event');
      contactsStreamController.add(event);
    });
  }

  void _listenFocusTextEditing() {
    searchContactsController.searchFocusNode.addListener(() {
      if (searchContactsController.searchFocusNode.hasFocus) {
        searchContactsController.isSearchModeNotifier.value = true;
      } else {
        searchContactsController.isSearchModeNotifier.value = false;
      }
    });
  }

  @override
  void dispose() {
    searchContactsController.dispose();
    fetchContactsController.dispose();
    contactsStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ContactsTabView(contactsController: this);
}