import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';

class HoverActionsWidget extends StatefulWidget {
  const HoverActionsWidget({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;

  final Widget child;

  @override
  State<HoverActionsWidget> createState() => _HoverActionsWidgetState();
}

class _HoverActionsWidgetState extends State<HoverActionsWidget> {
  final ValueNotifier<bool> isHoverNotifier = ValueNotifier(false);

  @override
  void dispose() {
    isHoverNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SendFileDialogStyle.paddingFileTile,
      child: InkWell(
        onHover: (isHover) {
          isHoverNotifier.value = isHover;
        },
        borderRadius: BorderRadius.circular(
          SendFileDialogStyle.inkwellSplashBorderRadius,
        ),
        onTap: () {},
        child: ValueListenableBuilder(
          valueListenable: isHoverNotifier,
          builder: (context, isHover, child) {
            return Stack(
              alignment: Alignment.centerRight,
              children: [
                child!,
                if (isHover)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.background,
                    ),
                    margin: SendFileDialogStyle.paddingRemoveButton,
                    child: TwakeIconButton(
                      icon: Icons.delete_outline_rounded,
                      iconColor: Theme.of(context).colorScheme.onSurface,
                      onTap: widget.onTap,
                    ),
                  ),
              ],
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
