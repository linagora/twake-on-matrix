import 'dart:ui' show ImageFilter;

import 'package:fluffychat/pages/chat_details/participant_list_item/chat_participant_context_menu_item.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

/// Mobile context menu overlay with floating participant item using Hero animation.
/// Displays dark background, elevated item with Hero animation, and context menu below.
class MobileContextMenuOverlay extends StatefulWidget {
  const MobileContextMenuOverlay({
    super.key,
    required this.itemPosition,
    required this.itemSize,
    required this.menuPosition,
    required this.menuActions,
    required this.member,
    required this.animation,
  });

  final Offset itemPosition;
  final Size itemSize;
  final Offset menuPosition;
  final List<ChatParticipantContextMenuItem> menuActions;
  final User member;
  final Animation<double> animation;

  @override
  State<MobileContextMenuOverlay> createState() =>
      _MobileContextMenuOverlayState();
}

class _MobileContextMenuOverlayState extends State<MobileContextMenuOverlay>
    with TwakeContextMenuMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showContextMenu();
    });
  }

  Future<void> _showContextMenu() async {
    final selectedIndex = await showTwakeContextMenu(
      offset: widget.menuPosition,
      context: context,
      listActions: widget.menuActions,
      respectLeftPosition: true,
    );

    if (mounted) {
      Navigator.of(context).pop(selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          FadeTransition(
            opacity: widget.animation,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          // Floating participant item with Hero animation
          Positioned(
            left: widget.itemPosition.dx,
            top: widget.itemPosition.dy,
            child: Hero(
              tag: 'participant_context_menu_${widget.member.id}',
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: widget.itemSize.width,
                  height: widget.itemSize.height,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildFloatingItem(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Avatar(
            mxContent: widget.member.avatarUrl,
            name: widget.member.calcDisplayname(),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.member.calcDisplayname(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: LinagoraTextStyle.material().bodyMedium2.copyWith(
                    color: LinagoraSysColors.material().onSurface,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  widget.member.id,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LinagoraRefColors.material().tertiary[30],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
