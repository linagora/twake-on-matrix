import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/pages/new_group/new_group_view.dart';
import 'package:matrix/matrix.dart';

class NewGroup extends StatefulWidget {
  const NewGroup({Key? key}) : super(key: key);

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends State<NewGroup> {
  final searchContactsController = SearchContactsController();
  final fetchContactsController = FetchContactsController();
  final contactStreamController = StreamController<Either<Failure, GetContactsSuccess>>();

  final selectedContactsMapNotifier = ValueNotifier<Map<PresentationContact, bool>>({});
  final haveSelectedContactsNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    searchContactsController.init();
    searchContactsController.onSearchKeywordChanged = (String text) {
      if (text.isEmpty) {
        fetchContactsController.fetchCurrentTomContacts();
      }
    };
    listenContactsStartList();
    listenSearchContacts();
  }

  void listenContactsStartList() {
    fetchContactsController.streamController.stream.listen((event) {
      Logs().d('NewGroupController::fetchContacts() - event: $event');
      contactStreamController.add(event);
    });
  }

  void listenSearchContacts() {
    searchContactsController.lookupStreamController.stream.listen((event) {
      Logs().d('NewGroupController::_fetchRemoteContacts() - event: $event');
      contactStreamController.add(event);
    });
  }

  void selectContact(PresentationContact contact) {
    final newSelectedContactsMap = Map<PresentationContact, bool>.from(selectedContactsMapNotifier.value);
    newSelectedContactsMap[contact] = true;
    selectedContactsMapNotifier.value = newSelectedContactsMap;

    haveSelectedContactsNotifier.value = selectedContactsMapNotifier.value.isNotEmpty;
  }

  void unselectContact(PresentationContact contact) {
    final newSelectedContactsMap = Map<PresentationContact, bool>.from(selectedContactsMapNotifier.value);
    newSelectedContactsMap.remove(contact);
    selectedContactsMapNotifier.value = newSelectedContactsMap;

    haveSelectedContactsNotifier.value = selectedContactsMapNotifier.value.isNotEmpty;
  }

  Set<PresentationContact> getAllContactsGroupChat() {
    final newContactsList = {
          PresentationContact(
            displayName: "You",
            matrixId: Matrix.of(context).client.userID,
          )
        };
    newContactsList.addAll(getSelectedValidContacts(contactsList));
    return newContactsList;
  }

    selectedContactsMapNotifier.dispose();
    haveSelectedContactsNotifier.dispose();
  }

  @override
  Widget build(BuildContext context) => NewGroupView(this);
}
