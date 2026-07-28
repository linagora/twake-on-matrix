import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:fluffychat/utils/search/search_options.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

mixin SearchRecentChat {
  static const _debouncerIntervalInMilliseconds = 300;

  final TextEditingController searchTextEditingController =
      TextEditingController();

  final Debouncer<String> debouncer = Debouncer(
    const Duration(milliseconds: _debouncerIntervalInMilliseconds),
    initialValue: '',
  );

  final recentlyChatsNotifier = ValueNotifier<List<Room>>([]);

  void handleSearchAction({
    required BuildContext context,
    required List<Room> filteredRoomsForAll,
    required String keyword,
  }) {
    if (keyword.isNotEmpty) {
      final matrixLocals = MatrixLocals(L10n.of(context)!);
      recentlyChatsNotifier.value = getIt.get<SearchEngine>().match(
        keyword,
        filteredRoomsForAll,
        fieldExtractors: [
          (Room room) => [room.getLocalizedDisplayname(matrixLocals)],
        ],
        options: const SearchOptions(diacriticSensitive: false),
      );
    } else {
      recentlyChatsNotifier.value = filteredRoomsForAll;
    }
  }

  void disposeSearchRecentChat() {
    recentlyChatsNotifier.dispose();
    searchTextEditingController.dispose();
  }

  void listenToSearch({
    required BuildContext context,
    required List<Room> filteredRoomsForAll,
  }) {
    searchTextEditingController.addListener(
      () => debouncer.value = searchTextEditingController.text,
    );
    debouncer.values.listen(
      (keyword) => handleSearchAction(
        context: context,
        filteredRoomsForAll: filteredRoomsForAll,
        keyword: keyword,
      ),
    );
  }
}
