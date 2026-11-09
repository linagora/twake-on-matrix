import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_style.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/folder_actions.dart';
import 'package:twake_chat/presentation/extensions/folder_extension.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:twake_chat/providers/room_list/room_list_filter_controller.dart';

/// « All », then the folders: what the room list shows.
class RoomListFilterBar extends ConsumerStatefulWidget {
  const RoomListFilterBar({super.key, this.enabled = true});

  /// False while rows are selected: the view must not change under them.
  final bool enabled;

  @override
  ConsumerState<RoomListFilterBar> createState() => _RoomListFilterBarState();
}

class _RoomListFilterBarState extends ConsumerState<RoomListFilterBar> {
  final _scrollController = ScrollController();
  bool _overflows = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _scrollController.animateTo(
      (position.pixels + delta).clamp(0, position.maxScrollExtent),
      duration: RoomListFilterStyle.scrollDuration,
      curve: Curves.easeOut,
    );
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    final overflows = notification.metrics.maxScrollExtent > 0;
    if (overflows != _overflows) {
      // The notification comes from layout: wait for the frame to end.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _overflows = overflows);
      });
    }
    return false;
  }

  void _select(RoomListFilter view) =>
      ref.read(roomListFilterControllerProvider.notifier).select(view);

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final selected = ref.watch(shownRoomListFilterProvider);
    final folders = ref.watch(roomListFoldersProvider);
    return SizedBox(
      height: RoomListFilterStyle.height,
      child: Row(
        children: [
          if (_overflows)
            _ScrollArrow(
              icon: Icons.chevron_left,
              tooltip: l10n.previous,
              onPressed: () => _scrollBy(-RoomListFilterStyle.scrollStep),
            ),
          Expanded(
            // The arrows come and go: the list must not be rebuilt with them.
            key: const ValueKey('room_list_filter_chips'),
            child: Semantics(
              label: l10n.roomListFilters,
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: _onMetrics,
                child: ListView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: l10n.all,
                      isSelected: selected is RoomListFilterAll,
                      onSelected: widget.enabled
                          ? () => _select(const RoomListFilter.all())
                          : null,
                    ),
                    for (final folder in folders)
                      _FilterChip(
                        label: folder.label(l10n),
                        emoji: folder.emoji,
                        color: folder.color,
                        isSelected: selected == RoomListFilter.of(folder),
                        onSelected: widget.enabled
                            ? () => _select(RoomListFilter.of(folder))
                            : null,
                        onMenu: widget.enabled
                            ? (context, position) => showFolderMenu(
                                context,
                                ref,
                                folder: folder,
                                position: position,
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_overflows)
            _ScrollArrow(
              icon: Icons.chevron_right,
              tooltip: l10n.next,
              onPressed: () => _scrollBy(RoomListFilterStyle.scrollStep),
            ),
        ],
      ),
    );
  }
}

class _ScrollArrow extends StatelessWidget {
  const _ScrollArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => LinagoraIconButton(
    icon: icon,
    iconSize: RoomListFilterStyle.arrowSize,
    padding: EdgeInsets.zero,
    tooltip: tooltip,
    onPressed: onPressed,
  );
}

/// The chip of the design system, with what a folder adds around it: its
/// colour, and its menu once selected or on a right click.
class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.emoji,
    this.color,
    this.onMenu,
  });

  final String label;
  final bool isSelected;

  /// Null disables the chip.
  final VoidCallback? onSelected;
  final String? emoji;
  final FolderColor? color;
  final void Function(BuildContext context, Offset position)? onMenu;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  @override
  void didUpdateWidget(_FilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) _scrollIntoView();
  }

  // The chip and its menu button, once laid out: the arrows they may bring in
  // narrow the row one frame later.
  void _scrollIntoView() {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      binding.addPostFrameCallback((_) {
        if (!mounted) return;
        // A chip already in view stays where it is.
        for (final policy in const [
          ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ]) {
          Scrollable.ensureVisible(
            context,
            alignmentPolicy: policy,
            duration: RoomListFilterStyle.scrollDuration,
            curve: Curves.easeOut,
          );
        }
      });
      binding.scheduleFrame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final onMenu = widget.onMenu;
    final onSelected = widget.onSelected;
    return Padding(
      padding: RoomListFilterStyle.chipMargin,
      child: GestureDetector(
        onSecondaryTapUp: onMenu == null
            ? null
            : (details) => onMenu(context, details.globalPosition),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null)
              Padding(
                padding: RoomListFilterStyle.chipLeadingPadding,
                child: CircleAvatar(
                  radius: RoomListFilterStyle.colorDotRadius,
                  backgroundColor: Color(color.argb),
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: RoomListFilterStyle.chipMaxWidth,
              ),
              child: LinagoraFilterChip(
                label: [?widget.emoji, widget.label].join(' '),
                selected: widget.isSelected,
                onSelected: onSelected == null ? null : (_) => onSelected(),
              ),
            ),
            if (widget.isSelected && onMenu != null)
              Builder(
                builder: (context) => LinagoraIconButton(
                  key: const ValueKey('room_list_filter_menu'),
                  icon: Icons.more_vert,
                  iconSize: RoomListFilterStyle.menuIconSize,
                  padding: EdgeInsets.zero,
                  tooltip: L10n.of(context)!.more,
                  onPressed: () {
                    final box = context.findRenderObject()! as RenderBox;
                    onMenu(
                      context,
                      box.localToGlobal(box.size.center(Offset.zero)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
