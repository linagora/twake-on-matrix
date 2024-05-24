import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';

class SendFileDialogActionsWidget extends StatelessWidget {
  const SendFileDialogActionsWidget({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SendFileDialogStyle.paddingFileTile,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // TODO: change to colorSurface when its approved
          // ignore: deprecated_member_use
          color: Theme.of(context).colorScheme.background,
        ),
        margin: SendFileDialogStyle.paddingRemoveButton,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SendFileDialogStyle.removeButtonColor(context),
              ),
              child: TwakeIconButton(
                icon: Icons.close,
                paddingAll: SendFileDialogStyle.paddingAllRemoveButton,
                iconColor: Theme.of(context).colorScheme.onSurface,
                onTap: onTap,
                size: SendFileDialogStyle.removeButonSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
