import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_item.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_style.dart';

/// The phone variant of RoomListFilterBar: one row of pills that scrolls
/// under an edge fade. A long press opens a folder's menu.
class RoomListFilterPills extends ConsumerWidget {
  const RoomListFilterPills({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final items = ref.watchRoomListFilterItems(l10n, enabled: enabled);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: RoomListFilterStyle.pillsMaxTextScale,
      child: SizedBox(
        height: RoomListFilterStyle.pillsHeight,
        child: Semantics(
          label: l10n.roomListFilters,
          child: _EndFade(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: RoomListFilterStyle.pillsPadding,
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: RoomListFilterStyle.pillsSpacing),
              itemBuilder: (context, index) {
                final item = items[index];
                final color = item.color;
                return _Pill(
                  label: item.label,
                  dotColor: color == null ? null : Color(color.argb),
                  isSelected: item.isSelected,
                  onTap: item.onSelected,
                  onLongPress: item.onMenu,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EndFade extends StatelessWidget {
  const _EndFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: AlignmentDirectional.centerStart,
        end: AlignmentDirectional.centerEnd,
        stops: [0, 1 - RoomListFilterStyle.pillsFadeWidth / rect.width, 1],
        colors: const [Colors.black, Colors.black, Colors.transparent],
      ).createShader(rect, textDirection: textDirection),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
    this.onLongPress,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? dotColor;
  final void Function(BuildContext context, Offset position)? onLongPress;

  Offset _center(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    final onLongPress = this.onLongPress;
    final dotColor = this.dotColor;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? colors.primary : colors.surface,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress == null
              ? null
              : () => onLongPress(context, _center(context)),
          child: Container(
            height: RoomListFilterStyle.pillHeight,
            constraints: const BoxConstraints(
              maxWidth: RoomListFilterStyle.chipMaxWidth,
            ),
            padding: RoomListFilterStyle.pillContentPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  CircleAvatar(
                    radius: RoomListFilterStyle.colorDotRadius,
                    backgroundColor: dotColor,
                  ),
                  const SizedBox(width: RoomListFilterStyle.pillDotGap),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LinagoraTextStyle.material().labelLarge.copyWith(
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
