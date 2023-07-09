import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/model/extensions/contact/presentation_contact_list_extension.dart';
import 'package:fluffychat/domain/usecase/fetch_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/search/search_interactor.dart';
import 'package:fluffychat/mixin/comparable_presentation_search_mixin.dart';
import 'package:fluffychat/pages/search/search_controller.dart';
import 'package:fluffychat/pages/search/search_view.dart';
import 'package:fluffychat/presentation/mixin/load_more_search_mixin.dart';
import 'package:fluffychat/presentation/model/presentation_search.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:vrouter/vrouter.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => SearchController();
}

class SearchController extends State<Search>  with ComparablePresentationSearchMixin, LoadMoreSearchMixin {

  static const int limitPrefetchedRecentChats = 3;
  static const int limitSearchingPrefetchedRecentContacts = 30;
  static const int limitPrefetchedRecentContacts = 7;

  bool isSearching = false;
  bool isSearchMode = false;
  ValueNotifier? isSearchModeNotifier;

  SearchContactAndRecentChatController? searchContactAndRecentChatController;
  final AutoScrollController recentChatsController = AutoScrollController();
  final ScrollController customScrollController = ScrollController();
  final _fetchContactsInteractor = getIt.get<FetchContactsInteractor>();
  final _searchContactsAndRecentChatInteractor = getIt.get<SearchContactsAndRecentChatInteractor>();
  final getContactStream = StreamController<Either<Failure, GetContactsSuccess>>();
  final contactsStreamController = BehaviorSubject<Either<Failure, GetContactsSuccess>>();
  final getContactAndRecentChatStream = StreamController<Either<Failure, GetContactAndRecentChatSuccess>>();
  final contactsAndRecentChatStreamController = BehaviorSubject<Either<Failure, GetContactAndRecentChatSuccess>>();

  Future<ProfileInformation?> getProfile(BuildContext context, PresentationSearch contact) async {
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


  void listenContactsStartList() {
    getContactStream.stream.listen((event) {
      Logs().d('SearchController::getContactStream() - event: $event');
      contactsStreamController.add(event);
    });

    getContactAndRecentChatStream.stream.listen((event) {
      Logs().d('SearchController::getContactAndRecentChatStream() - event: $event');
      contactsAndRecentChatStreamController.add(event);
    });
  }

  void _fetchCurrentTomContacts({
    int? limit,
    int? offset,
  }) {
    _fetchContactsInteractor.execute(limit: limit, offset: offset).listen((event) {
      getContactStream.add(event);
    });
  }

  void _getContactAndRecentChat() {
    _searchContactsAndRecentChatInteractor.execute(
      rooms: Matrix.of(context).client.rooms,
      matrixLocalizations: MatrixLocals(L10n.of(context)!),
      keyword: '',
      limitRecentChats: limitPrefetchedRecentChats,
      limitContacts: limitSearchingPrefetchedRecentContacts,
    ).listen((event) {
      getContactAndRecentChatStream.add(event);
    });
  }

  List<PresentationSearch> getContactsFromFetchStream(Either<Failure, GetContactsSuccess> event) {
    return event.fold<List<PresentationSearch>>(
      (failure) => <PresentationSearch>[],
      (success) {
        final currentContacts = success.contacts.expand((contact) => contact.toPresentationContacts());
        updateLastContactIndex(oldContactList.length);
        oldContactList = currentContacts.toList().toPresentationSearchList();
        lastContactIndexNotifier.value = oldContactList.length;
        return oldContactList;
      },
    ).toList();
  }

  List<PresentationSearch> getContactsAndRecentChatStream(Either<Failure, GetContactAndRecentChatSuccess> event) {
    return event.fold<List<PresentationSearch>>(
      (failure) => <PresentationSearch>[],
      (success) {
        final contactsAndRecentChat = success.presentationSearches;
        updateLastContactAndRecentChatIndex(contactsAndRecentChat.length);
        return contactsAndRecentChat;
      },
    ).toList();
  }

  void listenSearchContactAndRecentChat() {
    searchContactAndRecentChatController?.getContactAndRecentChatStream.stream.listen((event) {
      Logs().d('SearchController::getContactAndRecentChatStream() - event: $event');
      getContactAndRecentChatStream.add(event);
    });
  }

  void goToChatScreen(PresentationSearch presentationSearch) {
    if (presentationSearch.isContact) {
      showFutureLoadingDialog(
        context: context,
        future: () async {
          if (presentationSearch.directChatMatrixID != null && presentationSearch.directChatMatrixID!.isNotEmpty) {
            final roomId = await Matrix.of(context).client.startDirectChat(presentationSearch.directChatMatrixID!);
            VRouter.of(context).toSegments(['rooms', roomId]);
          }
        },
      );
    } else {
      if (presentationSearch.matrixId != null) {
        VRouter.of(context).toSegments(['rooms', presentationSearch.matrixId!]);
      }
    }

  }

  @override
  void initState() {
    searchContactAndRecentChatController = SearchContactAndRecentChatController(context);
    isSearchModeNotifier = ValueNotifier(false);
    listenContactsStartList();
    listenSearchContactAndRecentChat();
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        searchContactAndRecentChatController?.init();
        _fetchCurrentTomContacts(limit: limitPrefetchedRecentContacts);
        _getContactAndRecentChat();
      }
    });
  }

  @override
  void dispose() {
    recentChatsController.dispose();
    customScrollController.dispose();
    getContactStream.close();
    contactsStreamController.close();
    getContactAndRecentChatStream.close();
    contactsAndRecentChatStreamController.close();
    searchContactAndRecentChatController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchView(this);
}
