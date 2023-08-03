

import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/usecase/search/search_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';


class SearchContactsAndChatsController {
  
  final BuildContext context;
  
  SearchContactsAndChatsController(this.context);

  static const int limitPrefetchedRecentChats = 3;
  static const debouncerIntervalInMilliseconds = 300;
  final SearchRecentChatInteractor _searchRecentChatInteractor = getIt.get<SearchRecentChatInteractor>();
  final SearchContactsInteractor _searchContactsInteractor = getIt.get<SearchContactsInteractor>();

  final recentAndContactsNotifier = ValueNotifier<Either<Failure, Success>>(const Right(GetContactAndRecentChatInitial()));
  Debouncer<String>? _debouncer;

  MatrixLocalizations get matrixLocalizations => MatrixLocals(L10n.of(context)!);
  List<Room> get rooms => Matrix.of(context).client.rooms;

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
      Logs().d("SearchContactAndRecentChatController::_initializeDebouncer: searchKeyword: $keyword");
      searchChats(keyword: keyword);
    });
  }

  void fetchPreSearchChat() {
    _searchRecentChatInteractor.execute(
      keyword: '',
      matrixLocalizations: matrixLocalizations,
      rooms: rooms,
      limit: limitPrefetchedRecentChats
    ).listen((event) => mapPreSearchChatToPresentation(event, isLoadMore: false));
  }

  void searchChats({required String keyword}) {
    if (keyword.isEmpty) {
      return fetchPreSearchChat();
    }
    _searchRecentChatInteractor.execute(
      keyword: keyword,
      matrixLocalizations: matrixLocalizations,
      rooms: rooms,
    ).listen((event) => mapPreSearchChatToPresentation(event, isLoadMore: false));
  }

  void mapPreSearchChatToPresentation(Either<Failure, GetContactAndRecentChatSuccess> event, {required bool isLoadMore}) {
    final oldPresentation = isLoadMore 
      ? recentAndContactsNotifier.value.fold(
          (failure) => null, 
          (success) => success is GetContactAndRecentChatPresentation ? success : null) 
      : null;
    final newEvent = event.map((success) => success.toPresentation(oldPresentation: oldPresentation));
    recentAndContactsNotifier.value = newEvent;
    checkListNotEnoughToDisplay();
  }

  void checkListNotEnoughToDisplay() {
    recentAndContactsNotifier.value.fold(
      (failure) {
        return;
      },
      (success) {
        if (!(success is GetContactAndRecentChatPresentation 
          && success.shouldLoadMoreContacts
          && success.searchResult.length <= 10
        )) {
          return;
        }
        loadMoreContacts();
      }
    );
  }

  void loadMoreContacts() => recentAndContactsNotifier.value.fold(
    (failure) {
      return;
    },
    (success) {
      if (!(success is GetContactAndRecentChatPresentation && success.shouldLoadMoreContacts)) {
        return;
      }
      _searchContactsInteractor.execute(
        keyword: success.keyword,
        matrixLocalizations: matrixLocalizations,
        offset: success.contactsOffset
      ).listen((event) => mapPreSearchChatToPresentation(event, isLoadMore: true));
    }
  );

  void onSearchBarChanged(String keyword) {
    _debouncer?.value = keyword;
  }

  void dispose() {
    _debouncer?.cancel();
    recentAndContactsNotifier.dispose();
  }
}