import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_all_contacts_state.dart';
import 'package:fluffychat/domain/app_state/search/search_state.dart';
import 'package:fluffychat/domain/usecase/get_all_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:fluffychat/presentation/model/search/presentation_search_state.dart';
import 'package:fluffychat/presentation/model/search/presentation_search_state_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class SearchContactsAndChatsController {
  final BuildContext context;

  SearchContactsAndChatsController(this.context);

  static const int limitPrefetchedRecentChats = 3;
  static const limitContactsPerPage = 20;
  static const debouncerIntervalInMilliseconds = 300;
  static const minimumItemsListDisplay = 20;
  final SearchRecentChatInteractor _searchRecentChatInteractor =
      getIt.get<SearchRecentChatInteractor>();
  final _searchContactsInteractor = getIt.get<GetAllContactsInteractor>();
  bool _isLoadingMore = false;

  final recentAndContactsNotifier = ValueNotifier<Either<Failure, Success>>(
    Right(SearchInitial()),
  );
  Debouncer<String>? _debouncer;

  MatrixLocalizations get _matrixLocalizations =>
      MatrixLocals(L10n.of(context)!);

  List<Room> get _rooms => Matrix.of(context).client.rooms;

  void init() {
    _initializeDebouncer();
    fetchPreSearchChat();
  }

  void _initializeDebouncer() {
    _debouncer = Debouncer(
      const Duration(milliseconds: debouncerIntervalInMilliseconds),
      initialValue: '',
    );

    _debouncer?.values.listen((keyword) async {
      Logs().d(
        "SearchContactAndRecentChatController::_initializeDebouncer: searchKeyword: $keyword",
      );
      searchChats(keyword: keyword);
    });
  }

  void fetchPreSearchChat() {
    _searchRecentChatInteractor
        .execute(
          keyword: '',
          matrixLocalizations: _matrixLocalizations,
          rooms: _rooms,
          limit: limitPrefetchedRecentChats,
        )
        .listen(
          (event) => mapPreSearchChatToPresentation(event, isLoadMore: false),
        );
  }

  void searchChats({required String keyword}) {
    if (keyword.isEmpty) {
      return fetchPreSearchChat();
    }
    _searchRecentChatInteractor
        .execute(
          keyword: keyword,
          matrixLocalizations: _matrixLocalizations,
          rooms: _rooms,
        )
        .listen(
          (event) => mapPreSearchChatToPresentation(event, isLoadMore: false),
        );
  }

  void mapPreSearchChatToPresentation(
    Either<Failure, Success> event, {
    required bool isLoadMore,
  }) {
    Logs()
        .d("SearchContactsAndChatsController::mapPreSearchChatToPresentation");
    final oldPresentation = isLoadMore
        ? recentAndContactsNotifier.value.fold(
            (failure) => null,
            (success) =>
                success is GetContactAndRecentChatPresentation ? success : null,
          )
        : null;
    final newEvent = event.map(
      (success) => success is GetContactsAllSuccess
          ? success.toPresentation(
              oldPresentation: oldPresentation,
            )
          : success is SearchRecentChatSuccess
              ? success.toPresentation()
              : success,
    );
    recentAndContactsNotifier.value = newEvent;
    checkListNotEnoughToDisplay();
  }

  void checkListNotEnoughToDisplay() {
    recentAndContactsNotifier.value.fold((failure) {
      return;
    }, (success) {
      if (!(success is GetContactAndRecentChatPresentation &&
          success.tomContacts.length <= minimumItemsListDisplay)) {
        return;
      }
      loadMoreContacts();
    });
  }

  void loadMoreContacts() => recentAndContactsNotifier.value.fold((failure) {
        return;
      }, (success) {
        if (!(success is GetContactAndRecentChatPresentation &&
            !_isLoadingMore)) {
          return;
        }
        Logs().d(
          "SearchContactsAndChatsController::loadMoreContacts: keyword: ${success.keyword}",
        );
        _isLoadingMore = true;
        _searchContactsInteractor
            .execute(
              keyword: success.keyword,
              limit: limitContactsPerPage,
            )
            .listen(
              (event) => {
                _isLoadingMore = false,
                mapPreSearchChatToPresentation(event, isLoadMore: true),
              },
            );
      });

  void onSearchBarChanged(String keyword) {
    _debouncer?.value = keyword;
  }

  void dispose() {
    _debouncer?.cancel();
    recentAndContactsNotifier.dispose();
  }
}
