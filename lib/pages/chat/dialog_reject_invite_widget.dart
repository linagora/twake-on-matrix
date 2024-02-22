import 'package:fluffychat/pages/chat/dialog_reject_invite_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum DialogRejectInviteResult {
  reject,
  cancel,
}

class DialogRejectInviteWidget extends StatelessWidget {
  const DialogRejectInviteWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: UnconstrainedBox(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                DialogAcceptInviteStyle.borderRadiusDialog,
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            margin: DialogAcceptInviteStyle.marginDialog,
            padding: DialogAcceptInviteStyle.paddingDialog,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: DialogAcceptInviteStyle.paddingTitle,
                  child: Column(
                    children: [
                      Text(
                        L10n.of(context)!.declineTheInvitation,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16.0),
                      SizedBox(
                        width: DialogAcceptInviteStyle.dialogTextWidth,
                        child: Text(
                          L10n.of(context)!
                              .doYouReallyWantToDeclineThisInvitation,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: DialogAcceptInviteStyle.paddingButton,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionButton(
                        context: context,
                        text: L10n.of(context)!.declineAndRemove,
                        onPressed: () => Navigator.of(context)
                            .pop(DialogRejectInviteResult.reject),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        context: context,
                        text: L10n.of(context)!.cancel,
                        onPressed: () => Navigator.of(context)
                            .pop(DialogRejectInviteResult.cancel),
                      ),
                    ],
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.onPressed,
    required this.context,
  });

  final String text;
  final VoidCallback? onPressed;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(
        DialogAcceptInviteStyle.borderRadiusActionButton,
      ),
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            DialogAcceptInviteStyle.borderRadiusActionButton,
          ),
        ),
        padding: DialogAcceptInviteStyle.paddingActionButton,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
    );
  }
}
