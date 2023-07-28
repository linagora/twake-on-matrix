

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/search/search_state.dart';
import 'package:fluffychat/domain/usecase/search/pre_search_recent_contacts_interactor.dart';
import 'package:fluffychat/mixin/comparable_presentation_search_mixin.dart';
import 'package:fluffychat/pages/search/search_contacts_and_chats_controller.dart';
import 'package:fluffychat/pages/search/search_view.dart';
import 'package:fluffychat/presentation/mixin/load_more_search_mixin.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:vrouter/vrouter.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => SearchController();
}

class SearchController extends State<Search> with ComparablePresentationSearchMixin, LoadMoreSearchMixin {

  static const int limitPrefetchedRecentChats = 3;
  static const int limitSearchingPrefetchedRecentContacts = 30;
  static const int limitPrefetchedRecentContacts = 5;

  SearchContactsAndChatsController? searchContactAndRecentChatController;
  final AutoScrollController recentChatsController = AutoScrollController();
  final _preSearchRecentContactsInteractor = PreSearchRecentContactsInteractor();
  final preSearchRecentContactsNotifier = ValueNotifier<Either<Failure, Success>>(Right(SearchInitial()));

  final TextEditingController textEditingController = TextEditingController();

  void fetchPreSearchRecentContacts() {
    _preSearchRecentContactsInteractor.execute(
      recentRooms: Matrix.of(context).client.rooms,
      limit: limitPrefetchedRecentContacts
    ).listen((value) {
      preSearchRecentContactsNotifier.value = value;
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
    searchContactAndRecentChatController = SearchContactsAndChatsController(context);
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        searchContactAndRecentChatController?.init();
        listenForScrollChanged(controller: searchContactAndRecentChatController);
        fetchPreSearchRecentContacts();
        textEditingController.addListener(() {
          onSearchBarChanged(textEditingController.text);
        });
      }
    });
  }

  void onSearchBarChanged(String keyword) {
    searchContactAndRecentChatController?.onSearchBarChanged(keyword);
  }

  void onCloseSearchTapped() {
    textEditingController.clear();
  }

  void clearSearchBar() {
    textEditingController.clear();
  }

  @override
  void dispose() {
    recentChatsController.dispose();
    searchContactAndRecentChatScrollController.dispose();
    searchContactAndRecentChatController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchView(this);
}
