import 'package:fluffychat/pages/chat/events/button_content.dart';
import 'package:fluffychat/pages/chat/events/encrypted_mixin.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EncryptedContent extends StatelessWidget with EncryptedMixin {
  final Event event;

  const EncryptedContent({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ButtonContent(
      onTap: () => verifyOrRequestKey(context, event),
      icon: Icons.lock,
      title: L10n.of(context)!.thisMessageHasBeenEncrypted,
    );
  }
}
