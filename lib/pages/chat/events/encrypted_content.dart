import 'package:fluffychat/pages/chat/events/encrypted_content_style.dart';
import 'package:fluffychat/pages/chat/events/encrypted_mixin.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EncryptedContent extends StatelessWidget with EncryptedMixin {
  final Event event;

  const EncryptedContent({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EncryptedContentStyle.parentPadding,
      child: InkWell(
        onTap: () => verifyOrRequestKey(context, event),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onError,
                    shape: BoxShape.circle,
                  ),
                  padding: EncryptedContentStyle.leadingIconPadding,
                  child: Icon(
                    Icons.lock,
                    color: Theme.of(context).colorScheme.primary,
                    size: EncryptedContentStyle.leadingIconSize,
                  ),
                ),
                const SizedBox(width: EncryptedContentStyle.leadingAndTextGap),
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: EncryptedContentStyle.textMaxWidth,
                  ),
                  child: Text(
                    maxLines: 2,
                    L10n.of(context)!.thisMessageHasBeenEncrypted,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
