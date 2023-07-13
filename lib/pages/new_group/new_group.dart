import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/config/routes.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notiifer.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/pages/new_group/new_group_info_controller.dart';
import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/pages/new_group/new_group_view.dart';
import 'package:matrix/matrix.dart';

class NewGroup extends StatefulWidget {
  const NewGroup({Key? key}) : super(key: key);

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends State<NewGroup>
  with ComparablePresentationContactMixin {
  final searchContactsController = SearchContactsController();
  final fetchContactsController = FetchContactsController();
  final contactStreamController = StreamController<Either<Failure, GetContactsSuccess>>();
  final groupNameTextEditingController = TextEditingController();

  final selectedContactsMapNotifier = SelectedContactsMapChangeNotifier();
  final haveGroupNameNotifier = ValueNotifier(false);

  final groupNameFocusNode = FocusNode();

  String groupName = "";

  static const maxScrollOffsetAllowedInPixel = 380.0;

  @override
  void initState() {
    super.initState();
    searchContactsController.init();
    onSearchKeywordChanged();
    listenContactsStartList();
    listenSearchContacts();
    listenGroupNameChanged();
    fetchContactsController.fetchCurrentTomContacts();
    fetchContactsController.listenForScrollChanged(fetchContactsController: fetchContactsController);
    searchContactsController.onSearchKeywordChanged = (searchKey) {
      disableLoadMoreInSearch();
    };
  }

  void disableLoadMoreInSearch() {
    fetchContactsController.allowLoadMore = searchContactsController.searchKeyword.isEmpty;
  }

  @override
  void dispose() {
    super.dispose();
    contactStreamController.close();
    searchContactsController.dispose();
    fetchContactsController.dispose();
    groupNameTextEditingController.dispose();

    selectedContactsMapNotifier.dispose();
    haveGroupNameNotifier.dispose();
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

  void onSearchKeywordChanged() {
    searchContactsController.onSearchKeywordChanged = (String text) {
      if (text.isEmpty) {
        fetchContactsController.fetchCurrentTomContacts();
      } else {
        fetchContactsController.haveMoreCountactsNotifier.value = false;
      }
    };
  }

  Iterable<PresentationContact> get contactsList 
    => selectedContactsMapNotifier.contactsList;

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

  void moveToNewGroupInfoScreen() async {
    groupNameFocusNode.unfocus();
    await showGeneralDialog(
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      context: context,
      useRootNavigator: false,
      barrierColor: Colors.white,
      transitionBuilder: (context, animation1, animation2, widget) {
        return AppRoutes.rightToLeftTransition(
          animation1,
          animation2,
          NewGroupChatInfo(
            contactsList: getAllContactsGroupChat(),
            newGroupController: this,
          )
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => NewGroupView(this);
}
