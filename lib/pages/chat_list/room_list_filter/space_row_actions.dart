import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_style.dart';
import 'package:twake_chat/widgets/twake_components/unread_count_badge.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';

/// What the row of a space holds at its end: its counts, « + » and its fold.
class SpaceRowActions extends StatelessWidget {
  const SpaceRowActions({super.key, required this.name, required this.space});

  final String name;
  final SpaceRowData space;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final sys = LinagoraSysColors.material();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (space.unreadCount > 0)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: RoomListFilterStyle.pillGap,
            ),
            child: UnreadCountBadge(
              count: space.unreadCount,
              backgroundColor: sys.primary,
            ),
          ),
        if (space.mentionCount > 0)
          Semantics(
            label: l10n.spaceMentioned,
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: RoomListFilterStyle.pillGap,
              ),
              child: LinagoraSidebarBadge(
                label: '@',
                backgroundColor: sys.error,
                foregroundColor: sys.onError,
              ),
            ),
          ),
        if (space.onAddSubspace != null)
          LinagoraIconButton(
            icon: Icons.add,
            iconSize: RoomListFilterStyle.arrowSize,
            tooltip: l10n.addSubspaceTo(name),
            onPressed: space.onAddSubspace,
          ),
        if (space.fold != SpaceFold.none)
          LinagoraIconButton(
            icon: space.fold == SpaceFold.open
                ? Icons.expand_more
                : Icons.chevron_right,
            iconSize: RoomListFilterStyle.arrowSize,
            tooltip: space.fold == SpaceFold.open
                ? l10n.hideRoomsOf(name)
                : l10n.showRoomsOf(name),
            onPressed: space.onToggleFold,
          ),
      ],
    );
  }
}
