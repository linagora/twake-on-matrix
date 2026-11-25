import 'dart:async';

import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/domain/matrix_events/call_event_types.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/video_call/usecases/start_video_call_usecase.provider.dart';
import 'package:twake_chat/pages/call/call_screen.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_video_call_controller.dart';
import 'package:twake_chat/pages/chat/chat_video_call_state.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

class ChatVideoCallButton extends ConsumerStatefulWidget {
  final ChatController controller;

  const ChatVideoCallButton(this.controller, {super.key});

  @override
  ConsumerState<ChatVideoCallButton> createState() =>
      _ChatVideoCallButtonState();
}

class _ChatVideoCallButtonState extends ConsumerState<ChatVideoCallButton> {
  Future<void> _start(String baseUrl) async {
    final room = widget.controller.room;
    final userId = room?.client.userID;
    if (room == null || userId == null) return;
    final l10n = L10n.of(context)!;
    try {
      await ref
          .read(chatVideoCallControllerProvider(userId, room.id).notifier)
          .start(
            ref.read(startVideoCallUseCaseProvider(room.client)),
            baseUrl: baseUrl,
            startedTitle: l10n.videoCallStartedTitle,
          );
    } on VideoCallException {
      if (mounted) TwakeSnackBar.show(context, l10n.failedToStartVideoCall);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.controller.room;
    final userId = room?.client.userID;
    final (:tokenServiceUrl, :meetUrl) = ref.watch(
      loginHomeserverSummaryProvider.select(
        (summary) => (
          tokenServiceUrl: summary?.callTokenServiceUrl,
          meetUrl: summary?.videoCallBaseUrl,
        ),
      ),
    );
    if (room == null ||
        userId == null ||
        !widget.controller.canStartVideoCall(tokenServiceUrl ?? meetUrl)) {
      return const SizedBox.shrink();
    }
    final l10n = L10n.of(context)!;
    if (tokenServiceUrl != null) {
      if (room.canChangeStateEvent(CallEventTypes.callMember)) {
        return TwakeIconButton(
          icon: Icons.videocam_outlined,
          tooltip: l10n.startCall,
          onTap: () => unawaited(
            CallScreen.open(
              context,
              roomId: room.id,
              title: room.getLocalizedDisplayname(),
            ),
          ),
          preferBelow: false,
        );
      }
    }
    // D15: a member who may not write the call membership keeps the Meet link.
    if (meetUrl == null) return const SizedBox.shrink();
    if (ref.watch(chatVideoCallControllerProvider(userId, room.id))
        is ChatVideoCallStarting) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return TwakeIconButton(
      icon: Icons.videocam_outlined,
      tooltip: l10n.startVideoCall,
      onTap: () => unawaited(_start(meetUrl)),
      preferBelow: false,
    );
  }
}
