import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_item.dart';
import 'package:twake_chat/widgets/twake_components/filter_pills.dart';

/// The phone variant of RoomListFilterBar. A long press opens a folder's menu.
class RoomListFilterPills extends ConsumerWidget {
  const RoomListFilterPills({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final items = ref.watchRoomListFilterItems(l10n, enabled: enabled);
    return FilterPills(
      semanticsLabel: l10n.roomListFilters,
      pills: [
        for (final item in items)
          FilterPill(
            label: item.label,
            dotColor: switch (item.color) {
              final color? => Color(color.argb),
              null => null,
            },
            isSelected: item.isSelected,
            onTap: item.onSelected,
            onMenu: item.onMenu,
          ),
      ],
    );
  }
}
