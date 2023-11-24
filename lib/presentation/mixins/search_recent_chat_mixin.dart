import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

mixin SearchRecentChat {
  final TextEditingController searchTextEditingController =
      TextEditingController();

  final recentlyChatsNotifier = ValueNotifier<List<Room>>([]);

  void handleSearchAction({
    required BuildContext context,
    required List<Room> filteredRoomsForAll,
  }) {
    if (searchTextEditingController.text.isNotEmpty) {
      final matchedRooms = filteredRoomsForAll
          .where(
            (room) => room
                .getLocalizedDisplayname(MatrixLocals(L10n.of(context)!))
                .toLowerCase()
                .contains(searchTextEditingController.text.toLowerCase()),
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
}
