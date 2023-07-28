

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
    ).listen((event) {
      recentAndContactsNotifier.value = event;
    });
  }

  void searchChats({required String keyword}) {
    _searchRecentChatInteractor.execute(
      keyword: keyword,
      matrixLocalizations: matrixLocalizations,
      rooms: rooms,
    ).listen((event) {
      recentAndContactsNotifier.value = event;
    });
  }

  void loadMoreContacts(String keyword) {
    if (!shouldLoadMoreContacts) {
      return;
    }
    _searchContactsInteractor.execute(
      keyword: keyword,
      matrixLocalizations: MatrixLocals(L10n.of(context)!),
      offset: 0
    ).listen((event) {
      recentAndContactsNotifier.value = event;
    });
  }

  bool get shouldLoadMoreContacts {
    return false;
  }

  void onSearchBarChanged(String keyword) {
    _debouncer?.value = keyword;
  }

  void dispose() {
    _debouncer?.cancel();
    recentAndContactsNotifier.dispose();
  }
}