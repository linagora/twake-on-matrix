import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/folder_actions.dart';
import 'package:twake_chat/presentation/extensions/folder_extension.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_filter_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';

/// One chip of a filter row: « All » or a folder.
class RoomListFilterItem {
  const RoomListFilterItem({
    required this.label,
    required this.isSelected,
    this.color,
    this.onSelected,
    this.onMenu,
  });

  final String label;
  final bool isSelected;
  final FolderColor? color;

  /// Null while the row is disabled.
  final VoidCallback? onSelected;

  /// Null for « All » and while the row is disabled.
  final void Function(BuildContext context, Offset position)? onMenu;
}

extension RoomListFilterItems on WidgetRef {
  /// « All », then the folders. Watches providers: call it from `build`.
  List<RoomListFilterItem> watchRoomListFilterItems(
    L10n l10n, {
    required bool enabled,
  }) {
    final selected = watch(shownRoomListFilterProvider);
    final folders = watch(roomListFoldersProvider);
    void select(RoomListFilter view) =>
        read(roomListFilterControllerProvider.notifier).select(view);
    return [
      RoomListFilterItem(
        label: l10n.all,
        isSelected: selected is RoomListFilterAll,
        onSelected: enabled ? () => select(const RoomListFilter.all()) : null,
      ),
      for (final folder in folders)
        RoomListFilterItem(
          label: [?folder.emoji, folder.label(l10n)].join(' '),
          color: folder.color,
          isSelected: selected == RoomListFilter.of(folder),
          onSelected: enabled ? () => select(RoomListFilter.of(folder)) : null,
          onMenu: enabled
              ? (context, position) => unawaited(
                  showFolderMenu(
                    context,
                    this,
                    folder: folder,
                    position: position,
                  ),
                )
              : null,
        ),
    ];
  }
}
