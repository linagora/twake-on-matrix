import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/key_verification/key_verification_sas_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/encryption.dart';

class KeyVerificationEmojiView extends StatelessWidget {
  final List<KeyVerificationEmoji> emojis;
  final VoidCallback onDontMatch;
  final VoidCallback onMatch;

  const KeyVerificationEmojiView({
    super.key,
    required this.emojis,
    required this.onDontMatch,
    required this.onMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: KeyVerificationSasStyle.headingPadding,
          child: Text(
            L10n.of(context)!.verifyEmojiTitle,
            textAlign: TextAlign.center,
            style: KeyVerificationSasStyle.titleStyle(context),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final emoji in emojis)
              SizedBox(
                width: KeyVerificationSasStyle.emojiTileSize,
                height: KeyVerificationSasStyle.emojiTileSize,
                child: Center(
                  child: Text(
                    emoji.emoji,
                    style: const TextStyle(
                      fontSize: KeyVerificationSasStyle.emojiFontSize,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapTitleToSupporting),
        Text(
          L10n.of(context)!.verifyEmojiDescription,
          textAlign: TextAlign.center,
          style: KeyVerificationSasStyle.supportingStyle(context),
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapMascotToHeading),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onDontMatch,
              child: Text(
                L10n.of(context)!.dontMatch,
                style: KeyVerificationSasStyle.textButtonStyle(context),
              ),
            ),
            const SizedBox(width: KeyVerificationSasStyle.gapEmojiButtons),
            Material(
              color: KeyVerificationSasStyle.primaryColor,
              borderRadius: BorderRadius.circular(
                KeyVerificationSasStyle.buttonRadius,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onMatch,
                child: Padding(
                  padding: KeyVerificationSasStyle.filledButtonPadding,
                  child: Text(
                    L10n.of(context)!.match,
                    style: KeyVerificationSasStyle.filledButtonTextStyle(
                      context,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
