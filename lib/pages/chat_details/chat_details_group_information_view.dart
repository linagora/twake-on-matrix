import 'package:twake_chat/pages/chat_details/chat_details_view_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatDetailsGroupInformationView extends StatefulWidget {
  const ChatDetailsGroupInformationView({
    super.key,
    required this.height,
    required this.maxHeight,
    required this.animationController,
    this.displayName,
    this.subTitle,
    this.onTap,
  });

  final double height;
  final double maxHeight;
  final AnimationController animationController;
  final String? displayName;
  final String? subTitle;
  final VoidCallback? onTap;

  @override
  State<ChatDetailsGroupInformationView> createState() =>
      _ChatDetailsGroupInformationViewState();
}

class _ChatDetailsGroupInformationViewState
    extends State<ChatDetailsGroupInformationView> {
  late final LinagoraRefColors refColors;
  late final LinagoraSysColors sysColors;
  bool isTextSelected = false;
  final GlobalKey _displayNameKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    refColors = LinagoraRefColors.material();
    sysColors = LinagoraSysColors.material();
  }

  /// Taps on the group name are left to the [SelectionArea] so the name can
  /// be selected and copied without toggling the avatar.
  bool _isOnDisplayName(Offset globalPosition) {
    final renderBox =
        _displayNameKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return false;
    final localPosition = renderBox.globalToLocal(globalPosition);
    return renderBox.size.contains(localPosition);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SelectionArea(
      onSelectionChanged: (value) {
        final newSelected = value != null && value.plainText.isNotEmpty;
        if (newSelected != isTextSelected) {
          setState(() => isTextSelected = newSelected);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          if (_isOnDisplayName(details.globalPosition)) {
            return;
          }
          if (!isTextSelected) {
            widget.onTap?.call();
            return;
          }

          FocusScope.of(context).unfocus();
        },
        child: Container(
          height: Tween<double>(
            begin: widget.height,
            end: widget.maxHeight,
          ).transform(widget.animationController.value),
          padding: ChatDetailViewStyle.mainPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(
                height: ChatDetailViewStyle.avatarSize,
                width: ChatDetailViewStyle.avatarSize,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Tween<Alignment>(
                  begin: Alignment.center,
                  end: Alignment.centerLeft,
                ).transform(widget.animationController.value),
                child: Text(
                  widget.displayName ?? '',
                  key: _displayNameKey,
                  style: textTheme.titleLarge?.copyWith(
                    color: ColorTween(
                      begin: sysColors.onSurface,
                      end: sysColors.onPrimary,
                    ).transform(widget.animationController.value),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.subTitle != null)
                Align(
                  alignment: Tween<Alignment>(
                    begin: Alignment.center,
                    end: Alignment.centerLeft,
                  ).transform(widget.animationController.value),
                  child: Text(
                    widget.subTitle!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: ColorTween(
                        begin: refColors.tertiary[30],
                        end: sysColors.onPrimary,
                      ).transform(widget.animationController.value),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
