import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/usecase/fetch_contacts_interactor.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/forward/presentation_forward.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class Forward extends StatefulWidget {

  const Forward({Key? key}) : super(key: key);

  @override
  ForwardController createState() => ForwardController();
}

class ForwardController extends State<Forward> with ComparablePresentationContactMixin {

  final _fetchContactsInteractor = getIt.get<FetchContactsInteractor>();
  final streamController = StreamController<Either<Failure, GetContactsSuccess>>();

  final AutoScrollController forwardListController = AutoScrollController();


  List<ForwardToSelection> selectedEvents = [];
  bool get selectMode => selectedEvents.isNotEmpty;

  @override
  void initState() {
    super.initState();
    listenContactsStartList();
    fetchCurrentTomContacts();
  }

  @override
  void dispose() {
    super.dispose();
    streamController.close();
  }

  void fetchCurrentTomContacts() {
    _fetchContactsInteractor
        .execute()
        .listen((event) {
      streamController.add(event);
    });
  }

  void listenContactsStartList() {
    streamController.stream.listen((event) {
      Logs().d('ForwardController::listenContactsStartList() - event: $event');
    });
  }

  void onSelectChat(ForwardToSelection presentationForward) {
    if (selectedEvents.contains(presentationForward)) {
      setState(
        () => selectedEvents.remove(presentationForward),
      );
    } else {
      setState(
        () => selectedEvents.add(presentationForward),
      );
    }
    selectedEvents.sort((current, next) => current.id.compareTo(next.id));
    Logs().d("onSelectChat: $selectedEvents");
  }

  final ActiveFilter _activeFilterAllChats = ActiveFilter.allChats;

  bool Function(Room) getRoomFilterByActiveFilter(ActiveFilter activeFilter) {
    switch (activeFilter) {
      case ActiveFilter.allChats:
        return (room) => !room.isSpace && !room.isStoryRoom;
      case ActiveFilter.groups:
        return (room) =>
        !room.isSpace && !room.isDirectChat && !room.isStoryRoom;
      case ActiveFilter.messages:
        return (room) =>
        !room.isSpace && room.isDirectChat && !room.isStoryRoom;
      case ActiveFilter.spaces:
        return (r) => r.isSpace;
    }
  }

  List<Room> get filteredRoomsForAll => Matrix.of(context)
    .client
    .rooms
    .where(getRoomFilterByActiveFilter(_activeFilterAllChats))
    .toList();

  @override
  Widget build(BuildContext context) => ForwardView(this);
}

enum EmojiPickerType { reaction, keyboard }
