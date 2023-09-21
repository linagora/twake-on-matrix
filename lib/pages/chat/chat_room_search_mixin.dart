import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/chat_room_search_state.dart';
import 'package:fluffychat/domain/app_state/search/search_state.dart';
import 'package:fluffychat/domain/usecase/room/chat_room_search_interactor.dart';
import 'package:flutter/widgets.dart';
import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

mixin ChatRoomSearchMixin {
  static const int _maxRequestHistory = 10;

  final isSearchingNotifier = ValueNotifier(false);
  final searchTextController = TextEditingController();
  final searchStatus =
      ValueNotifier<Either<Failure, Success>>(Right(SearchInitial()));
  final canGoUp = ValueNotifier(false);
  final canGoDown = ValueNotifier(false);

  final _searchInteractor = getIt.get<ChatRoomSearchInteractor>();

  int _historyCount = 100;
  Timeline? Function()? _getTimeline;
  void Function(int)? _scrollToIndex;

  static const _debouncerDuration = Duration(milliseconds: 300);
  final _debouncer = Debouncer(
    _debouncerDuration,
    initialValue: '',
  );

  void toggleSearch() {
    isSearchingNotifier.value = !isSearchingNotifier.value;
    clearSearch();
  }

  void onSearchChanged(String text) {
    _debouncer.setValue(text);
  }

  void initializeSearch({
    required Timeline? Function()? getTimeline,
    Function(int)? scrollToIndex,
    required int historyCount,
  }) {
    _scrollToIndex = scrollToIndex;
    _historyCount = historyCount;
    _getTimeline = getTimeline;
    _debouncer.values.listen((keyword) {
      _handleSearch(keyword);
    });
  }

  void disposeSearch() {
    _debouncer.cancel();
    searchTextController.dispose();
  }

  void _handleSearch(String keyword) {
    final timeline = _getTimeline?.call();
    if (timeline == null) return;
    _searchInteractor
        .execute(
      timeline: timeline,
      keyword: keyword,
      currentEventIndex: -1,
      direction: Direction.b,
      limitPerRequest: _historyCount,
      maxRequest: _maxRequestHistory,
    )
        .listen(
      (event) {
        Logs().v(
          "ChatRoomSearchMixin::_handleSearch $event",
        );
        searchStatus.value = event;
        _scrollToEvent(event);
        canGoUp.value = event.getSuccessOrNull<ChatRoomSearchSuccess>() != null;
        canGoDown.value = false;
      },
    );
  }

  void clearSearch() {
    searchTextController.clear();
    searchStatus.value = Right(SearchInitial());
    canGoDown.value = false;
    canGoUp.value = false;
  }

  void _scrollToEvent(Either<Failure, Success> event) {
    final index = event.getSuccessOrNull<ChatRoomSearchSuccess>()?.eventIndex;
    if (index != null) {
      _scrollToIndex?.call(index);
    }
  }

  void goUpSearchResult(BuildContext context) {
    _goSearchResult(context, direction: Direction.b);
  }

  void goDownSearchResult(BuildContext context) {
    _goSearchResult(context, direction: Direction.f);
  }

  void _goSearchResult(BuildContext context, {required Direction direction}) {
    final lastSuccess =
        searchStatus.value.getSuccessOrNull<ChatRoomSearchSuccess>();
    final timeline = _getTimeline?.call();
    if (timeline == null || lastSuccess == null) return;
    _searchInteractor
        .execute(
      timeline: timeline,
      keyword: lastSuccess.keyword,
      currentEventIndex: lastSuccess.eventIndex,
      direction: direction,
      limitPerRequest: _historyCount,
      maxRequest: _maxRequestHistory,
    )
        .listen(
      (event) {
        Logs().v(
          "ChatRoomSearchMixin::_goSearchResult $event",
        );
        _scrollToEvent(event);
        if (event.getSuccessOrNull() != null) {
          searchStatus.value = event;
          switch (direction) {
            case Direction.b:
              canGoDown.value = true;
              break;
            case Direction.f:
              canGoUp.value = true;
              break;
            default:
          }
        } else if (event.isLeft()) {
          Fluttertoast.showToast(msg: L10n.of(context)!.noMoreResult);
          switch (direction) {
            case Direction.b:
              canGoUp.value = false;
              break;
            case Direction.f:
              canGoDown.value = false;
              break;
            default:
          }
        }
      },
    );
  }
}
