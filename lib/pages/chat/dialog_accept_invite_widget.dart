import 'package:fluffychat/pages/chat/dialog_accept_invite_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

enum DialogAcceptInviteResult {
  accept,
  reject,
  cancel,
}

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
      child: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(DialogAcceptInviteResult.cancel);
          return false;
        },
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
                Padding(
                  padding: DialogAcceptInviteStyle.paddingTitle,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: displayInviterName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LinagoraSysColors.material().primary,
                          ),
                      children: [
                        TextSpan(
                          text: L10n.of(context)!.askToInvite,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color:
                                    LinagoraRefColors.material().tertiary[30],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: DialogAcceptInviteStyle.paddingButton,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionButton(
                        context: context,
                        text: L10n.of(context)!.rejectInvite,
                        onPressed: () => Navigator.of(context)
                            .pop(DialogAcceptInviteResult.reject),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        context: context,
                        text: L10n.of(context)!.acceptInvite,
                        isAccept: true,
                        onPressed: () => Navigator.of(context)
                            .pop(DialogAcceptInviteResult.accept),
                        colorBackground: Theme.of(context).colorScheme.primary,
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
    this.isAccept = false,
    this.colorBackground,
  });

  final String text;
  final VoidCallback? onPressed;
  final BuildContext context;
  final bool isAccept;
  final Color? colorBackground;

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
          color: colorBackground,
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
