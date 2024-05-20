import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/public_room_state.dart';
import 'package:fluffychat/domain/usecase/search/public_room_interactor.dart';
import 'package:fluffychat/pages/search/public_room/public_room_actions.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/presentation/model/search/public_room/presentation_search_public_room.dart';
import 'package:fluffychat/presentation/model/search/public_room/presentation_search_public_room_empty.dart';
import 'package:fluffychat/presentation/model/search/public_room/presentation_search_public_room_state.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

class SearchPublicRoomController with SearchDebouncerMixin {
  SearchPublicRoomController();

  final PublicRoomInteractor _publicRoomInteractor =
      getIt.get<PublicRoomInteractor>();

  final searchResultsNotifier =
      ValueNotifier<PresentationSearchPublicRoomUIState>(
    PresentationSearchPublicRoomInitial(),
  );

  static const int _limitPublicRoomSearchFilter = 20;

  PublicRoomQueryFilter? _filter;

  String? _server;

  bool get searchTermIsNotEmpty =>
      _filter?.genericSearchTerm?.isNotEmpty == true;

  String? get genericSearchTerm => _filter?.genericSearchTerm;

  void init() {
    initializeDebouncer((keyword) {
      _updateFilter(keyword);
      _updateServer(keyword);

      if (keyword.isEmpty) return;

      if (keyword.isRoomAlias()) {
        _resetSearchResults();
        _searchPublicRoom();
      } else if (keyword.isRoomId()) {
        _handleKeywordIsRoomId();
      }
    });
  }

  void _updateFilter(String keyword) {
    _filter = PublicRoomQueryFilter(
      genericSearchTerm: keyword,
    );
  }

  void _updateServer(String keyword) {
    _server = keyword.getServerNameFromRoomAlias();
  }

  void _resetSearchResults() {
    searchResultsNotifier.value = PresentationSearchPublicRoom(
      searchResults: [],
    );
  }

  void _searchPublicRoom() {
    _publicRoomInteractor
        .execute(
          filter: _filter,
          limit: _limitPublicRoomSearchFilter,
          server: _server,
        )
        .listen(
          (searchResult) => _handleListenSearchPublicRoom(searchResult),
        );
  }

  void _handleListenSearchPublicRoom(Either<Failure, Success> searchResult) {
    searchResult.fold((failure) => _resetSearchResults(), (success) {
      if (!searchTermIsNotEmpty) {
        return;
      }

      if (success is PublicRoomSuccess) {
        if (success.publicRoomsChunk == null) {
          searchResultsNotifier.value = PresentationSearchPublicRoomEmpty();
        } else {
          searchResultsNotifier.value = PresentationSearchPublicRoom(
            searchResults: success.publicRoomsChunk!,
          );
        }
      }
    });
  }

  void _handleKeywordIsRoomId() {
    searchResultsNotifier.value = PresentationSearchPublicRoomEmpty();
  }

  void _viewRoom(BuildContext context, String roomId) {
    context.go('/rooms/$roomId');
  }

  void joinRoom(BuildContext context, String roomIdOrAlias) async {
    final client = Matrix.of(context).client;
    final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => client.joinRoom(roomIdOrAlias),
    );
    if (result.error == null) {
      if (client.getRoomById(result.result!) == null) {
        await client.onSync.stream.firstWhere(
          (sync) => sync.rooms?.join?.containsKey(result.result) ?? false,
        );
      }
      if (!client.getRoomById(result.result!)!.isSpace) {
        context.go('/rooms/${result.result!}');
      }
      Navigator.of(context, rootNavigator: false).pop();
      return;
    }
  }

  void handlePublicRoomActions(
    BuildContext context,
    PublicRoomsChunk room,
    PublicRoomActions action,
  ) {
    switch (action) {
      case PublicRoomActions.join:
        joinRoom(context, room.canonicalAlias ?? room.roomId);
        break;
      case PublicRoomActions.view:
        _viewRoom(context, room.roomId);
        break;
    }
  }

  PublicRoomActions? getAction(
    BuildContext context,
    PublicRoomsChunk room,
  ) {
    final client = Matrix.of(context).client;
    if (client.getRoomById(room.roomId) != null) {
      return PublicRoomActions.view;
    } else if (room.joinRule == 'public') {
      return PublicRoomActions.join;
    }
    return null;
  }

  void onSearchBarChanged(String keyword) {
    if (keyword.isRoomAlias() || keyword.isRoomId()) {
      setDebouncerValue(keyword);
    } else {
      setDebouncerValue('');
      _resetSearchResults();
    }
  }

  void dispose() {
    super.disposeDebouncer();
    searchResultsNotifier.dispose();
    _resetSearchResults();
    disposeDebouncer();
    _server = null;
    _filter = null;
  }
}
