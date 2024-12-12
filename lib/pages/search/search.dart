import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/search_state.dart';
import 'package:fluffychat/domain/usecase/search/pre_search_recent_contacts_interactor.dart';
import 'package:fluffychat/pages/search/search_contacts_and_chats_controller.dart';
import 'package:fluffychat/pages/search/search_view.dart';
import 'package:fluffychat/pages/search/server_search_controller.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

class Search extends StatefulWidget {
  final VoidCallback? onCloseSearchPage;

  const Search({super.key, this.onCloseSearchPage});

  @override
  State<Search> createState() => SearchController();
}

class SearchController extends State<Search> {
  static const int limitPrefetchedRecentChats = 3;
  static const int limitPrefetchedRecentContacts = 5;
  static const _prefixLengthHighlight = 20;

  SearchContactsAndChatsController? searchContactAndRecentChatController;
  final serverSearchController = ServerSearchController();

  final _preSearchRecentContactsInteractor =
      getIt.get<PreSearchRecentContactsInteractor>();

  final preSearchRecentContactsNotifier =
      ValueNotifier<Either<Failure, Success>>(Right(SearchInitial()));

  final TextEditingController textEditingController = TextEditingController();

  final scrollController = ScrollController();

  Client get client => Matrix.of(context).client;

  bool get isShowMore =>
      textEditingController.value.text.isNotEmpty &&
      searchContactAndRecentChatController != null &&
      searchContactAndRecentChatController!
          .isShowChatsAndContactsNotifier.value;

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
        .substringToHighlight(
          searchWord,
          prefixLength: _prefixLengthHighlight,
        );
    return '$senderName: $bodyContent';
  }

  void fetchPreSearchRecentContacts() {
    _preSearchRecentContactsInteractor
        .execute(
      allRooms: Matrix.of(context).client.rooms,
      limit: limitPrefetchedRecentContacts,
    )
        .listen((value) {
      preSearchRecentContactsNotifier.value = value;
    });
  }

  void onSearchItemTap(PresentationSearch presentationSearch) async {
    if (presentationSearch is ContactPresentationSearch) {
      if (presentationSearch.matrixId?.isCurrentMatrixId(context) == true) {
        goToSettingsProfile();
        return;
      }
      onContactTap(presentationSearch);
    } else if (presentationSearch is RecentChatPresentationSearch) {
      onRecentChatTap(presentationSearch);
    }
  }

  void goToSettingsProfile() {
    context.go('/rooms/profile');
  }

  void onContactTap(ContactPresentationSearch contactPresentationSearch) {
    final roomId = Matrix.of(context)
        .client
        .getDirectChatFromUserId(contactPresentationSearch.matrixId!);
    if (roomId == null) {
      goToDraftChat(
        context: context,
        contactPresentationSearch: contactPresentationSearch,
      );
    } else {
      context.go('/rooms/$roomId');
    }
  }

  void onRecentChatTap(
    RecentChatPresentationSearch recentChatPresentationSearch,
  ) {
    Logs().d(
      'SearchController::onRecentChatTap() - MatrixID: ${recentChatPresentationSearch.id}',
    );
    context.go('/rooms/${recentChatPresentationSearch.id}');
  }

  void goToDraftChat({
    required BuildContext context,
    required ContactPresentationSearch contactPresentationSearch,
  }) {
    if (contactPresentationSearch.matrixId !=
        Matrix.of(context).client.userID) {
      context.go(
        '/rooms/draftChat',
        extra: {
          PresentationContactConstant.receiverId:
              contactPresentationSearch.matrixId ?? '',
          PresentationContactConstant.email:
              contactPresentationSearch.email ?? '',
          PresentationContactConstant.displayName:
              contactPresentationSearch.displayName ?? '',
          PresentationContactConstant.status: '',
        },
      );
    }
  }

  void goToChatScreenFormRecentChat(User user) async {
    Logs()
        .d('SearchController::getContactAndRecentChatStream() - event: $user');
    final roomIdResult = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => user.startDirectChat(),
    );
    if (roomIdResult.error != null) return;
    context.go('/rooms/${roomIdResult.result!}');
  }

  @override
  void initState() {
    searchContactAndRecentChatController =
        SearchContactsAndChatsController(context);
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        searchContactAndRecentChatController?.init();
        serverSearchController.initSearch(
          context: context,
        );
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
  }

  void clearSearchBar() {
    textEditingController.clear();
  }

  @override
  void dispose() {
    searchContactAndRecentChatController?.dispose();
    serverSearchController.dispose();
    preSearchRecentContactsNotifier.dispose();
    textEditingController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchView(this);
}
