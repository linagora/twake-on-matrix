import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

/// « Pierre is calling you », or « Clément · is calling you in General » in a
/// group, as Twake Space Chat says it (its D134).
class IncomingCallBanner extends StatelessWidget {
  const IncomingCallBanner({
    required this.ring,
    required this.onAnswer,
    required this.onDecline,
    super.key,
  });

  final CallRing ring;
  final VoidCallback onAnswer;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        key: const Key('incoming-call'),
        color: LinagoraRefColors.material().neutral[10],
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Caller(ring: ring),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RingButton(
                      key: const Key('decline-call'),
                      label: l10n.callDecline,
                      icon: Icons.call_end,
                      color: colors.error,
                      onPressed: onDecline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RingButton(
                      key: const Key('answer-call'),
                      label: l10n.callAnswer,
                      icon: Icons.call,
                      color: colors.success,
                      onPressed: onAnswer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Caller extends StatelessWidget {
  const _Caller({required this.ring});

  static const _avatarSize = 48.0;

  final CallRing ring;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final roomName = ring.roomName ?? '';
    final name = ring.isDirect ? roomName : ring.callerName ?? ring.senderId;
    final body = !ring.isDirect && name != roomName
        ? l10n.callIsCallingIn(roomName)
        : l10n.callIsCalling;
    final onDark = LinagoraSysColors.material().onPrimary;
    final textStyle = LinagoraTextStyle.material();
    return Row(
      children: [
        Avatar(mxContent: ring.avatarUrl, name: name, size: _avatarSize),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle.titleMedium.copyWith(color: onDark),
              ),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textStyle.bodyMedium.copyWith(color: onDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingButton extends StatelessWidget {
  const _RingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
    style: FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: LinagoraSysColors.material().onPrimary,
    ),
  );
}
