import 'package:fluffychat/pages/chat/events/button_content.dart';
import 'package:fluffychat/pages/chat/events/encrypted_mixin.dart';
import 'package:fluffychat/pages/chat/optional_selection_container_disabled.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class EncryptedContent extends StatelessWidget with EncryptedMixin {
  final Event event;

  const EncryptedContent({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return OptionalSelectionContainerDisabled(
      isEnabled: PlatformInfos.isWeb,
      child: ButtonContent(
        onTap: () => verifyOrRequestKey(context, event),
        icon: Icons.lock,
        title: L10n.of(context)!.thisMessageHasBeenEncrypted,
      ),
    );
  }
}
