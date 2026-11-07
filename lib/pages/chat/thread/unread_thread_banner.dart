import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

/// "New replies in a thread" at the top of a room, with "Open".
class UnreadThreadBanner extends StatelessWidget {
  const UnreadThreadBanner({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    return Material(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.forum_outlined, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.newRepliesInThread,
                style: LinagoraTextStyle.material().bodyMedium,
              ),
            ),
            TextButton(onPressed: onOpen, child: Text(l10n.openThread)),
          ],
        ),
      ),
    );
  }
}
