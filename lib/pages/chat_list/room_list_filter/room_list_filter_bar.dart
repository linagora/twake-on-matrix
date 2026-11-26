import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_item.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_style.dart';

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
  bool _canScrollBack = false;
  bool _canScrollForward = false;
  bool _arrowsUpdatePending = false;

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

  bool _onScroll(Notification notification) {
    if (notification is! ScrollMetricsNotification &&
        notification is! ScrollNotification) {
      return false;
    }
    if (_arrowsUpdatePending) return false;
    _arrowsUpdatePending = true;
    // The notification may come from layout: read the position once it ends.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _updateArrows())
      ..ensureVisualUpdate();
    return false;
  }

  void _updateArrows() {
    _arrowsUpdatePending = false;
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final overflows = position.maxScrollExtent > position.minScrollExtent;
    final canScrollBack = position.pixels > position.minScrollExtent;
    final canScrollForward = position.pixels < position.maxScrollExtent;
    if (overflows == _overflows &&
        canScrollBack == _canScrollBack &&
        canScrollForward == _canScrollForward) {
      return;
    }
    setState(() {
      _overflows = overflows;
      _canScrollBack = canScrollBack;
      _canScrollForward = canScrollForward;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final items = ref.watchRoomListFilterItems(l10n, enabled: widget.enabled);
    return SizedBox(
      height: RoomListFilterStyle.height,
      child: Row(
        children: [
          if (_overflows)
            _ScrollArrow(
              icon: Icons.chevron_left,
              tooltip: l10n.previous,
              visible: _canScrollBack,
              onPressed: () => _scrollBy(-RoomListFilterStyle.scrollStep),
            ),
          Expanded(
            // The arrows come and go: the list must not be rebuilt with them.
            key: const ValueKey('room_list_filter_chips'),
            child: Semantics(
              label: l10n.roomListFilters,
              child: NotificationListener<Notification>(
                onNotification: _onScroll,
                child: ListView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final item in items)
                      _FilterChip(
                        label: item.label,
                        color: item.color,
                        isSelected: item.isSelected,
                        onSelected: item.onSelected,
                        onMenu: item.onMenu,
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
              visible: _canScrollForward,
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
    required this.visible,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool visible;
  final VoidCallback onPressed;

  // A hidden arrow keeps its place: the chips must not shift under the finger.
  @override
  Widget build(BuildContext context) => Visibility(
    visible: visible,
    maintainState: true,
    maintainAnimation: true,
    maintainSize: true,
    child: LinagoraIconButton(
      icon: icon,
      iconSize: RoomListFilterStyle.arrowSize,
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      onPressed: onPressed,
    ),
  );
}

/// The chip of the design system, with what a folder adds around it: its
/// colour, and its menu once selected or on a right click.
class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
    this.onMenu,
  });

  final String label;
  final bool isSelected;

  /// Null disables the chip.
  final VoidCallback? onSelected;
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
                label: widget.label,
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
