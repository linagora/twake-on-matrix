import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

class CallTile extends StatelessWidget {
  const CallTile({required this.participant, super.key});

  static const _width = 160.0;
  static const _avatarSize = 64.0;

  final CallParticipant participant;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final displayName = participant.displayName ?? participant.userId;
    final name = participant.isLocal ? l10n.you : displayName;
    final onDark = LinagoraSysColors.material().onPrimary;
    final textStyle = LinagoraTextStyle.material();
    return Semantics(
      label: [
        name,
        if (!participant.isMicrophoneOn) l10n.callMicrophoneOff,
      ].join(', '),
      excludeSemantics: true,
      child: Container(
        width: _width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LinagoraRefColors.material().neutral[20],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: participant.isSpeaking
                ? LinagoraSysColors.material().primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Avatar(
              mxContent: participant.avatarUrl,
              name: displayName,
              size: _avatarSize,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle.bodyMedium.copyWith(color: onDark),
            ),
            if (!participant.isMicrophoneOn)
              Text(
                l10n.callMicrophoneOff,
                style: textStyle.bodySmall.copyWith(color: onDark),
              ),
          ],
        ),
      ),
    );
  }
}
