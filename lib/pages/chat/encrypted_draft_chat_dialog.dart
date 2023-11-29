import 'package:fluffychat/pages/chat/encrypted_draft_chat_dialog_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum EncryptDraftChatResult {
  continueToDraft,
  cancel,
}

class EncryptedDraftChatDialog extends StatelessWidget {
  const EncryptedDraftChatDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(EncryptDraftChatResult.cancel);
          return false;
        },
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                EncryptedDraftChatDialogStyle.borderRadiusDialog,
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            width: EncryptedDraftChatDialogStyle.dialogSize,
            margin: EncryptedDraftChatDialogStyle.marginDialog,
            padding: EncryptedDraftChatDialogStyle.paddingDialog,
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EncryptedDraftChatDialogStyle.paddingTitle,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                L10n.of(context)!.startAnEncryptedDirectChat,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                            ),
                            SvgPicture.asset(
                              ImagePaths.icEncrypted,
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height:
                              EncryptedDraftChatDialogStyle.dialogContentGap,
                        ),
                        Text(
                          L10n.of(context)!.encryptionMessage,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          maxLines: 4,
                        ),
                        const SizedBox(
                          height:
                              EncryptedDraftChatDialogStyle.dialogContentGap,
                        ),
                        Text(
                          L10n.of(context)!.encryptionWarning,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EncryptedDraftChatDialogStyle.paddingButton,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(
                          context: context,
                          text: L10n.of(context)!.cancel,
                          isConfirmButton: false,
                          onPressed: () => Navigator.of(context)
                              .pop(EncryptDraftChatResult.cancel),
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          context: context,
                          text: L10n.of(context)!.continueProcess,
                          isConfirmButton: true,
                          onPressed: () => Navigator.of(context)
                              .pop(EncryptDraftChatResult.continueToDraft),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
    required this.isConfirmButton,
  });

  final String text;
  final VoidCallback? onPressed;
  final BuildContext context;
  final bool isConfirmButton;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(
        EncryptedDraftChatDialogStyle.borderRadiusActionButton,
      ),
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            EncryptedDraftChatDialogStyle.borderRadiusActionButton,
          ),
          color: isConfirmButton
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
        padding: EncryptedDraftChatDialogStyle.paddingActionButton,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isConfirmButton
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
    );
  }
}
