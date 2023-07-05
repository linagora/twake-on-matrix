import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/search/search_view.dart';
import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => SearchController();
}

class SearchController extends State<Search>  with ComparablePresentationContactMixin {

  static const int limitRecentChats = 3;
  static const int limitRecentContacts = 7;

  AutoScrollController recentChatsController = AutoScrollController();
  ScrollController customScrollController = ScrollController();
  final fetchContactsController = FetchContactsController();
  final contactsStreamController = BehaviorSubject<Either<Failure, GetContactsSuccess>>();

  isFilteredRecentChat(Room room) {
    return !room.isSpace && room.isDirectChat && !room.isStoryRoom;
  }

  List<Room> get filteredRoomsForAll => Matrix.of(context)
    .client
    .rooms
    .where((room) => !room.isSpace && !room.isStoryRoom)
    .take(limitRecentChats)
    .toList();

  void listenContactsStartList() {
    fetchContactsController.streamController.stream.listen((event) {
      Logs().d('SearchController::fetchContacts() - event: $event');
      contactsStreamController.add(event);
    });
  }

  Future<ProfileInformation?> getProfile(BuildContext context, PresentationContact contact) async {
    final client = Matrix.of(context).client;
    if (contact.matrixId == null) {
      return Future.error(Exception("MatrixId is null"));
    }
    try {
      final profile = await client.getUserProfile(contact.matrixId!);
      Logs().d("SearchController()::getProfiles(): ${profile.avatarUrl}");
      return profile;
    } catch (e) {
      return ProfileInformation(avatarUrl: null, displayname: contact.displayName);
    }
  }

  @override
  void initState() {
    listenContactsStartList();
    super.initState();
    fetchContactsController.fetchCurrentTomContacts(limit: limitRecentContacts);
  }

  @override
  void dispose() {
    recentChatsController.dispose();
    customScrollController.dispose();
    fetchContactsController.dispose();
    contactsStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchView(this);
}
