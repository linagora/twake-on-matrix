import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_row_divider.dart';

/// The last line of an open space: a dashed « + » where the avatars are, and
/// what it adds. A press starts the new room.
class AddToSpaceRow extends StatelessWidget {
  const AddToSpaceRow({super.key, required this.depth, required this.onTap});

  final int depth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = LinagoraSysColors.material().primary;
    return Padding(
      padding: ChatListItemStyle.padding,
      child: TwakeInkWell(
        isSelected: false,
        onTap: onTap,
        child: Container(
          height: ChatListItemStyle.spaceItemHeight,
          padding: ChatListItemStyle.paddingBody.add(
            EdgeInsetsDirectional.only(
              start: depth * ChatListItemStyle.depthIndent,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: ChatListItemStyle.paddingAvatar,
                child: CustomPaint(
                  painter: _DashedCirclePainter(primary),
                  child: SizedBox.square(
                    dimension: ChatListItemStyle.childAvatarSize,
                    child: Icon(Icons.add, color: primary),
                  ),
                ),
              ),
              Expanded(
                child: ChatListRowDivider(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      L10n.of(context)!.spaceAddRoom,
                      overflow: TextOverflow.ellipsis,
                      style: ListItemStyle.titleTextStyle().copyWith(
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter(this.color);

  static const _dashes = 16;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = (Offset.zero & size).deflate(paint.strokeWidth / 2);
    const step = 2 * 3.141592653589793 / _dashes;
    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(rect, i * step, step / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
