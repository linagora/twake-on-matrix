import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class NewPrivateChat extends StatefulWidget {
  const NewPrivateChat({Key? key}) : super(key: key);

  @override
  NewPrivateChatController createState() => NewPrivateChatController();
}

class NewPrivateChatController extends State<NewPrivateChat> {

  final searchContactsController = SearchContactsController();
  final fetchContactsController = FetchContactsController();
  final networkStreamController = StreamController<Either<Failure, GetContactsSuccess>>();

  @override
  void initState() {
    super.initState();
    searchContactsController.init();
    searchContactsController.onSearchKeywordChanged = (String text) {
      if (text.isEmpty) {
        fetchContactsController.fetchCurrentTomContacts();
      }
    };
    listenSearchContacts();
    listenContactsStartList();
    fetchContactsController.fetchCurrentTomContacts();
  }

  void listenContactsStartList() {
    fetchContactsController.streamController.stream.listen((event) {
      Logs().d('NewPrivateChatController::fetchContacts() - event: $event');
      networkStreamController.add(event);
    });
  }

  void listenSearchContacts() {
    searchContactsController.lookupStreamController.stream.listen((event) {
      Logs().d('NewPrivateChatController::_fetchRemoteContacts() - event: $event');
      networkStreamController.add(event);
    });
  }

  @override
  void dispose() {
    super.dispose();
    networkStreamController.close();
    searchContactsController.dispose();
    fetchContactsController.dispose();
  }

  @override
  Widget build(BuildContext context) => NewPrivateChatView(this);
}
