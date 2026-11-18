import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/search/search_state.dart';
import 'package:twake_chat/domain/usecase/search/pre_search_recent_contacts_interactor.dart';
import 'package:twake_chat/pages/search/public_groups_search_term.dart';
import 'package:twake_chat/pages/search/search_contacts_and_chats_controller.dart';
import 'package:twake_chat/pages/search/search_controller.dart';
import 'package:twake_chat/pages/search/search_state.dart';
import 'package:twake_chat/pages/search/search_view.dart';
import 'package:twake_chat/pages/search/server_search_controller.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:twake_chat/presentation/model/search/presentation_search.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/utils/scroll_controller_extension.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/scheduler.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

class Search extends ConsumerStatefulWidget {
  final VoidCallback? onCloseSearchPage;

  const Search({super.key, this.onCloseSearchPage});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends ConsumerState<Search>
    with WidgetsBindingObserver {
  static const int limitPrefetchedRecentChats = 3;
  static const int limitPrefetchedRecentContacts = 5;
  static const _prefixLengthHighlight = 20;

  SearchContactsAndChatsController? searchContactAndRecentChatController;
  final serverSearchController = ServerSearchController();

  final _preSearchRecentContactsInteractor = getIt
      .get<PreSearchRecentContactsInteractor>();

  final preSearchRecentContactsNotifier =
      ValueNotifier<Either<Failure, Success>>(Right(SearchInitial()));

  final TextEditingController textEditingController = TextEditingController();

  late final publicGroupsSearchTerm = PublicGroupsSearchTerm(
    textEditingController,
  );

  final scrollController = ScrollController();

  Client get client => ref.read(matrixClientProvider);

  bool get isShowMore =>
      textEditingController.value.text.isNotEmpty &&
      searchContactAndRecentChatController != null &&
      searchContactAndRecentChatController!
          .isShowChatsAndContactsNotifier
          .value;

  String get searchWord => textEditingController.text;

  bool get isSearchMatrixUserId =>
      searchWord.isValidMatrixId && searchWord.startsWith('@');

  String getBodyText(Event event, String searchWord) {
    final senderName = event.senderFromMemoryOrFallback.calcDisplayname(
      i18n: MatrixLocals(L10n.of(context)!),
    );

    final bodyContent = event
        .calcLocalizedBodyFallback(
          MatrixLocals(L10n.of(context)!),
          hideEdit: true,
          hideReply: true,
          plaintextBody: true,
          removeMarkdown: true,
        )
        .substringToHighlight(searchWord, prefixLength: _prefixLengthHighlight);
    return '$senderName: $bodyContent';
  }

  void fetchPreSearchRecentContacts() {
    _preSearchRecentContactsInteractor
        .execute(
          allRooms: client.joinedOrInvitedRooms,
          limit: limitPrefetchedRecentContacts,
        )
        .listen((value) {
          preSearchRecentContactsNotifier.value = value;
        });
  }

  void onSearchItemTap(PresentationSearch presentationSearch) {
    if (presentationSearch is ContactPresentationSearch) {
      final matrixId = presentationSearch.matrixId;
      if (matrixId == null || matrixId.isEmpty) return;
      unawaited(
        ref
            .read(searchControllerProvider.notifier)
            .openContact(
              matrixId: matrixId,
              displayName: presentationSearch.displayName,
            ),
      );
    } else if (presentationSearch is RecentChatPresentationSearch) {
      RoomRoute(roomid: presentationSearch.id).go(context);
    }
  }

  void _onStateChanged(SearchState? _, SearchState next) {
    switch (next) {
      case SearchOwnProfile():
        const ProfileRoute().go(context);
      case SearchRoom(:final roomId):
        RoomRoute(roomid: roomId).go(context);
      case SearchDraft(:final matrixId, :final displayName):
        context.go(
          '/rooms/draftChat',
          extra: {
            PresentationContactConstant.receiverId: matrixId,
            PresentationContactConstant.displayName: displayName ?? '',
            PresentationContactConstant.status: '',
          },
        );
      case SearchIdle() || SearchOpening():
        break;
    }
  }

  @override
  void initState() {
    searchContactAndRecentChatController = SearchContactsAndChatsController(
      context,
    );
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await searchContactAndRecentChatController?.init();
        serverSearchController.initSearch(context: context);
        fetchPreSearchRecentContacts();
        textEditingController.addListener(() {
          onSearchBarChanged(textEditingController.text);
        });
        scrollController.addLoadMoreListener(loadMore);
      }
    });
  }

  void onSearchBarChanged(String keyword) {
    searchContactAndRecentChatController?.onSearchBarChanged(keyword);
    serverSearchController.onSearchBarChanged(keyword);
  }

  void loadMore() {
    serverSearchController.loadMore();
  }

  void onCloseSearchTapped() {
    textEditingController.clear();
    final onCloseSearchPage = widget.onCloseSearchPage;
    if (onCloseSearchPage != null) {
      onCloseSearchPage();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void clearSearchBar() {
    textEditingController.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await searchContactAndRecentChatController
        ?.handleDidChangeAppLifecycleState(
          state,
          context: context,
          client: client,
        );
  }

  @override
  void dispose() {
    searchContactAndRecentChatController?.dispose();
    serverSearchController.dispose();
    preSearchRecentContactsNotifier.dispose();
    publicGroupsSearchTerm.dispose();
    textEditingController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchControllerProvider, _onStateChanged);
    return SearchView(this);
  }
}
