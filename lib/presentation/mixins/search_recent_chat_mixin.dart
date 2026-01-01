import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
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

  Future<void> handleSearchAction({
    required BuildContext context,
    required List<Room> filteredRoomsForAll,
    required String keyword,
  }) async {
    if (keyword.isNotEmpty) {
      final matchedRooms = <Room>[];

      // Process rooms in batches to avoid rate limiting
      const batchSize = 10;
      for (var i = 0; i < filteredRoomsForAll.length; i += batchSize) {
        final end = (i + batchSize < filteredRoomsForAll.length)
            ? i + batchSize
            : filteredRoomsForAll.length;
        final batch = filteredRoomsForAll.sublist(i, end);

        await Future.wait(
          batch.map((room) async {
            try {
              final displayName = await room.getUserDisplayName(
                matrixId: room.isDirectChat ? room.directChatMatrixID : null,
                i18n: MatrixLocals(L10n.of(context)!),
              );
              if (displayName.toLowerCase().contains(keyword.toLowerCase())) {
                matchedRooms.add(room);
              }
            } catch (e) {
              // Skip rooms that fail to load
              Logs().w('Failed to get display name for room ${room.id}: $e');
            }
          }),
        );

        // Small delay between batches to avoid rate limiting
        if (end < filteredRoomsForAll.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

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
      (keyword) async => await handleSearchAction(
        context: context,
        filteredRoomsForAll: filteredRoomsForAll,
        keyword: keyword,
      ),
    );
  }
}
