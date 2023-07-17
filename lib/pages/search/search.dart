import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/model/extensions/search/search_list_extension.dart';
import 'package:fluffychat/domain/usecase/search/search_interactor.dart';
import 'package:fluffychat/mixin/comparable_presentation_search_mixin.dart';
import 'package:fluffychat/pages/search/search_controller.dart';
import 'package:fluffychat/pages/search/search_view.dart';
import 'package:fluffychat/presentation/mixin/load_more_search_mixin.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
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
  final _searchContactsAndRecentChatInteractor = getIt.get<SearchContactsAndRecentChatInteractor>();
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
    getContactAndRecentChatStream.stream.listen((event) {
      Logs().d('SearchController::getContactAndRecentChatStream() - event: $event');
      contactsAndRecentChatStreamController.add(event);
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

  List<User> getContactsFromRecentChat() {
    final recentRooms = Matrix.of(context).client.rooms;
    final List<User> recentChatListPresentationSearch = [];

    for (final room in recentRooms) {
      final users = room.getParticipants()
        .where((user) => user.membership.isInvite == true && user.displayName != null)
        .toSet()
        .toList();

      for (final user in users) {
        final isDuplicateUser = recentChatListPresentationSearch
          .any((existingUser) => existingUser.displayName == user.displayName);

        if (!isDuplicateUser) {
          recentChatListPresentationSearch.add(user);
        }

        if (recentChatListPresentationSearch.length == limitPrefetchedRecentContacts) {
          break; // Stop getting participants after 7 or more have been added
        }
      }

      if (recentChatListPresentationSearch.length == limitPrefetchedRecentContacts) {
        break; // Stop getting participants after 7 or more have been added
      }
    }

    Logs().d('SearchController::getContactsFromRecentChat() - event: $recentChatListPresentationSearch');

    return recentChatListPresentationSearch;
  }

  List<PresentationSearch> getContactsAndRecentChatStream(Either<Failure, GetContactAndRecentChatSuccess> event) {
    return event.fold<List<PresentationSearch>>(
      (failure) => <PresentationSearch>[],
      (success) {
        final contactsAndRecentChat = success.search.toPresentationSearch();
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

  void goToChatScreenFormRecentChat(User user) async {
    Logs().d('SearchController::getContactAndRecentChatStream() - event: $user');
    final roomIdResult = await showFutureLoadingDialog(
      context: context,
      future: () => user.startDirectChat(),
    );
    if (roomIdResult.error != null) return;
    VRouter.of(context).toSegments(['rooms', roomIdResult.result!]);
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
        _getContactAndRecentChat();
      }
    });
  }

  @override
  void dispose() {
    recentChatsController.dispose();
    customScrollController.dispose();
    getContactAndRecentChatStream.close();
    contactsAndRecentChatStreamController.close();
    searchContactAndRecentChatController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchView(this);
}
