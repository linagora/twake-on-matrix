import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/call/call_controller.dart';
import 'package:twake_chat/pages/call/call_state.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

/// The call of a room (DECISION.md D15): before it, in it, or why it failed.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({required this.roomId, required this.title, super.key});

  final String roomId;
  final String title;

  static Future<void> open(
    BuildContext context, {
    required String roomId,
    required String title,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => CallScreen(roomId: roomId, title: title),
    ),
  );

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  var _isClosing = false;

  void _join() => unawaited(
    ref
        .read(callControllerProvider.notifier)
        .join(widget.roomId, isVideo: false),
  );

  bool _isThisRoom(CallState state) => switch (state) {
    CallIdle() => false,
    CallConnecting(:final roomId) ||
    CallConnected(:final roomId) ||
    CallFailed(:final roomId) => roomId == widget.roomId,
  };

  @override
  Widget build(BuildContext context) {
    ref.listen(callControllerProvider, (previous, next) {
      final wasInCall = previous is CallConnected || previous is CallConnecting;
      if (wasInCall && next is CallIdle && !_isClosing) {
        Navigator.of(context).pop();
      }
    });
    final state = ref.watch(callControllerProvider);
    final shown = _isThisRoom(state) ? state : const CallState.idle();
    final l10n = L10n.of(context)!;
    final textStyle = LinagoraTextStyle.material();
    final onDark = LinagoraSysColors.material().onPrimary;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _isClosing = true;
        if (_isThisRoom(ref.read(callControllerProvider))) {
          unawaited(ref.read(callControllerProvider.notifier).leave());
        }
      },
      child: Scaffold(
        backgroundColor: LinagoraRefColors.material().neutral[10],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: onDark,
          leading: CloseButton(color: onDark),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text(
            widget.title,
            style: textStyle.titleMedium.copyWith(color: onDark),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: switch (shown) {
            CallIdle() => _CallMessage(
              action: FilledButton(
                key: const Key('call-start'),
                onPressed: _join,
                child: Text(l10n.startCall),
              ),
            ),
            CallConnecting() => _CallMessage(
              text: l10n.callConnecting,
              action: const CircularProgressIndicator(),
            ),
            CallFailed(:final error) => _CallMessage(
              text: _describe(l10n, error),
              action: FilledButton(
                key: const Key('call-retry'),
                onPressed: _join,
                child: Text(l10n.callRetry),
              ),
            ),
            CallConnected(:final participants) => _CallStage(
              participants: participants,
            ),
          },
        ),
      ),
    );
  }

  static String _describe(L10n l10n, CallException error) => switch (error) {
    CallServiceUnavailableException() => l10n.callErrorNoService,
    CallEncryptionUnsupportedException() => l10n.callErrorEncrypted,
    CallNoPermissionException() => l10n.callErrorNoPermission,
    CallRoomNotFoundException() ||
    CallNoClientException() => l10n.callErrorRoomNotFound,
    CallTokenFailedException() => l10n.callErrorTokenFailed,
    CallMembershipFailedException() => l10n.callErrorMembershipFailed,
    CallConnectionFailedException() => l10n.callErrorConnectionFailed,
    CallMediaFailedException() => l10n.callErrorMediaFailed,
  };
}

class _CallMessage extends StatelessWidget {
  const _CallMessage({required this.action, this.text});

  final String? text;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text != null) ...[
              Text(
                text,
                textAlign: TextAlign.center,
                style: LinagoraTextStyle.material().bodyLarge.copyWith(
                  color: LinagoraSysColors.material().onPrimary,
                ),
              ),
              const SizedBox(height: 24),
            ],
            action,
          ],
        ),
      ),
    );
  }
}

class _CallStage extends ConsumerWidget {
  const _CallStage({required this.participants});

  final List<CallParticipant> participants;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final controller = ref.read(callControllerProvider.notifier);
    final isMicrophoneOn = participants
        .where((participant) => participant.isLocal)
        .any((participant) => participant.isMicrophoneOn);
    final danger = LinagoraSysColors.material().error;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final participant in participants)
                  _CallTile(participant: participant),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CallControl(
                key: const Key('call-microphone'),
                label: l10n.callMicrophone,
                icon: isMicrophoneOn ? Icons.mic : Icons.mic_off,
                color: isMicrophoneOn ? null : danger,
                isSelected: isMicrophoneOn,
                onPressed: () =>
                    unawaited(controller.setMicrophone(isOn: !isMicrophoneOn)),
              ),
              const SizedBox(width: 24),
              _CallControl(
                key: const Key('call-leave'),
                label: l10n.callLeave,
                icon: Icons.call_end,
                color: danger,
                onPressed: () => unawaited(controller.leave()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.participant});

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

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.isSelected,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final bool? isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onDark = LinagoraSysColors.material().onPrimary;
    return IconButton.filled(
      tooltip: label,
      isSelected: isSelected,
      onPressed: onPressed,
      iconSize: 28,
      style: IconButton.styleFrom(
        backgroundColor: color ?? LinagoraRefColors.material().neutral[30],
        foregroundColor: onDark,
        padding: const EdgeInsets.all(16),
      ),
      icon: Icon(icon),
    );
  }
}
