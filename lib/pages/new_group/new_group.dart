import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/config/routes.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/app_state/room/create_room_end_action_success.dart';
import 'package:fluffychat/domain/app_state/room/create_room_success.dart';
import 'package:fluffychat/pages/new_private_chat/create_room_controller.dart';
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
import 'package:vrouter/vrouter.dart';

class NewGroup extends StatefulWidget {
  const NewGroup({Key? key}) : super(key: key);

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends State<NewGroup> with ComparablePresentationContactMixin {
  final searchContactsController = SearchContactsController();
  final fetchContactsController = FetchContactsController();
  final contactStreamController = StreamController<Either<Failure, GetContactsSuccess>>();
  final groupNameTextEditingController = TextEditingController();
  final groupchatInfoScrollController = ScrollController();
  final createRoomStreamController = CreateRoomController();

  final selectedContactsMapNotifier = ValueNotifier<Map<PresentationContact, bool>>({});
  final haveSelectedContactsNotifier = ValueNotifier(false);
  final haveGroupNameNotifier = ValueNotifier(false);
  final isEnableEEEncryptionNotifier = ValueNotifier(true);

  final groupNameFocusNode = FocusNode();

  static const maxScrollOffsetAllowedInPixel = 380.0;
  final int maxFileSizeDefault = 5 * 1024 * 1024;

  String groupName = "";
  bool isGroupPublic = false;
  MatrixFile? avatar;

  @override
  void initState() {
    super.initState();
    searchContactsController.init();
    onSearchKeywordChanged();
    listenContactsStartList();
    listenSearchContacts();
    listenGroupNameChanged();
    fetchContactsController.fetchCurrentTomContacts();
    groupchatInfoScrollController.addListener(() {
      if (groupchatInfoScrollController.offset > maxScrollOffsetAllowedInPixel) {
        groupchatInfoScrollController.jumpTo(
          maxScrollOffsetAllowedInPixel, 
        );
      }
    });
    listenCreateRoom();
  }

  @override
  void dispose() {
    super.dispose();
    contactStreamController.close();
    searchContactsController.dispose();
    fetchContactsController.dispose();
    groupNameTextEditingController.dispose();

    selectedContactsMapNotifier.dispose();
    haveSelectedContactsNotifier.dispose();
    isEnableEEEncryptionNotifier.dispose();
    haveGroupNameNotifier.dispose();
  }

  void listenContactsStartList() {
    fetchContactsController.streamController.stream.listen((event) {
      Logs().d('NewGroupController::fetchContacts() - event: $event');
      contactStreamController.add(event);
    });
  }

  void listenCreateRoom() {
    createRoomStreamController.streamController.stream.listen((event) {
      Logs().d('NewGroupController::createRoom() - event: $event');
      event.fold(
        (failure) => {
          Logs().e('NewGroupController::createRoom() - failure: $failure'),
          createRoomStreamController.dispose(),
        },
        (Success success) {
          Logs().d('NewGroupController::createRoom() - success: $success');
          if (success is CreateRoomSuccess) {
            VRouter.of(context).toSegments(['rooms', success.roomId]);
          }

          if (success is CreateRoomEndActionSuccess) {
            createRoomStreamController.dispose();
          }
        },
      );
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
      }
    };
  }

  Iterable<PresentationContact> get contactsList => selectedContactsMapNotifier.value.keys;

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

  void autoScrollWhenExpandParticipants() {
    groupchatInfoScrollController.animateTo(
      MediaQuery.of(context).size.height, 
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) => NewGroupView(this);
}
