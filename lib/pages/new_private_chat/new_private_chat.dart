import 'dart:async';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:fluffychat/presentation/mixins/go_to_direct_chat_mixin.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:go_router/go_router.dart';

import 'package:matrix/matrix.dart';

class NewPrivateChat extends StatefulWidget {
  const NewPrivateChat({Key? key}) : super(key: key);

  @override
  NewPrivateChatController createState() => NewPrivateChatController();
}

class NewPrivateChatController extends State<NewPrivateChat>
    with ComparablePresentationContactMixin, GoToDraftChatMixin {
  final searchContactsController = SearchContactsController();
  final fetchContactsController = FetchContactsController();
  final networkStreamController = StreamController<Either<Failure, Success>>();

  final isShowContactsNotifier = ValueNotifier(true);

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
    fetchContactsController.listenForScrollChanged(
      fetchContactsController: fetchContactsController,
    );
    searchContactsController.onSearchKeywordChanged = (searchKey) {
      disableLoadMoreInSearch();
    };
  }

  void disableLoadMoreInSearch() {
    fetchContactsController.allowLoadMore =
        searchContactsController.searchKeyword.isEmpty;
  }

  void listenContactsStartList() {
    fetchContactsController.streamController.stream.listen((event) {
      Logs().d('NewPrivateChatController::fetchContacts() - event: $event');
      networkStreamController.add(event);
    });
  }

  void listenSearchContacts() {
    searchContactsController.lookupStreamController.stream.listen((event) {
      Logs().d(
        'NewPrivateChatController::_fetchRemoteContacts() - event: $event',
      );
      networkStreamController.add(event);
    });
  }

  void toggleContactsList() {
    isShowContactsNotifier.value = !isShowContactsNotifier.value;
    fetchContactsController.haveMoreCountactsNotifier.value =
        isShowContactsNotifier.value;
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
    networkStreamController.close();
    searchContactsController.dispose();
    fetchContactsController.dispose();
  }

  @override
  Widget build(BuildContext context) => NewPrivateChatView(this);
}
