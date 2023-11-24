import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
      final matchedRooms = filteredRoomsForAll
          .where(
            (room) => room
                .getLocalizedDisplayname(MatrixLocals(L10n.of(context)!))
                .toLowerCase()
                .contains(keyword.toLowerCase()),
          )
          .toList();
      recentlyChatsNotifier.value = matchedRooms;
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
