import 'package:fluffychat/pages/chat/dialog_accept_invite_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class DialogAcceptInviteWidget extends StatelessWidget {
  final String displayInviterName;

  const DialogAcceptInviteWidget({
    super.key,
    required this.displayInviterName,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
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
              const SizedBox(height: 24.0),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: displayInviterName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LinagoraSysColors.material().primary,
                      ),
                  children: [
                    TextSpan(
                      text: L10n.of(context)!.askToInvite,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LinagoraRefColors.material().tertiary[30],
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: DialogAcceptInviteStyle.paddingButton,
                child: Row(
                  children: [
                    _ActionButton(
                      context: context,
                      text: L10n.of(context)!.rejectInvite,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      context: context,
                      text: L10n.of(context)!.acceptInvite,
                      isAccept: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ),
            ],
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
    this.isAccept = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final BuildContext context;
  final bool isAccept;

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
          color: isAccept ? Theme.of(context).colorScheme.primary : null,
        ),
        padding: DialogAcceptInviteStyle.paddingActionButton,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isAccept
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
    );
  }
}
