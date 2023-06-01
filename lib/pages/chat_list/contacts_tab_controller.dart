import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:matrix/matrix.dart';

extension ContactTabController on ChatListController {
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
}