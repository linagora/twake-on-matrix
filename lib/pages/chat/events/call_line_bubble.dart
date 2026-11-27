import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/model/call/call_line.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/extensions/call_line_extension.dart';

/// A call as one bubble of the chat, with nothing to act on (DECISION.md D31).
class CallLineBubble extends StatelessWidget {
  const CallLineBubble({super.key, required this.line, required this.sentAt});

  final CallLine line;
  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final textTheme = Theme.of(
      context,
    ).extension<LinagoraTextThemeExtension>()!;
    final sysColors = LinagoraSysColors.material();
    final refColors = LinagoraRefColors.material();
    final statusColor = line.outcome == CallLineOutcome.answered
        ? sysColors.success
        : sysColors.error;
    final bubble = MessageBubble(
      isOwnMessage: line.isOutgoing,
      isAlignedToEnd: line.isOutgoing,
      padding: const EdgeInsets.all(LinagoraSpacing.base * 1.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            line.isVideo ? Icons.videocam : Icons.call,
            color: sysColors.primary,
          ),
          const SizedBox(width: LinagoraSpacing.base * 1.5),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.title(l10n),
                  style: textTheme.bodyMedium4.copyWith(
                    color: sysColors.onSurface,
                  ),
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(_arrowOf(line), size: 16, color: statusColor),
                    const SizedBox(width: LinagoraSpacing.base * 0.5),
                    Text(
                      line.status(l10n),
                      style: textTheme.bodyMedium3.copyWith(color: statusColor),
                    ),
                    const SizedBox(width: LinagoraSpacing.base),
                    Text(
                      DateFormat('HH:mm').format(sentAt),
                      style: textTheme.bodyMedium3.copyWith(
                        color: refColors.tertiary[30],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LinagoraSpacing.base * 2,
        vertical: LinagoraSpacing.base * 0.5,
      ),
      child: Align(
        alignment: line.isOutgoing
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: bubble,
      ),
    );
  }

  static IconData _arrowOf(CallLine line) {
    if (line.isOutgoing) return Icons.call_made;
    return line.outcome == CallLineOutcome.answered
        ? Icons.call_received
        : Icons.call_missed;
  }
}
