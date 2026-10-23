import 'dart:async';

import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/video_call/usecases/start_video_call_usecase.provider.dart';
import 'package:twake_chat/pages/chat/chat.dart';
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
  bool _isStarting = false;

  Future<void> _start(String baseUrl) async {
    final room = widget.controller.room;
    if (_isStarting || room == null) return;
    final l10n = L10n.of(context)!;
    setState(() => _isStarting = true);
    try {
      await ref
          .read(startVideoCallUseCaseProvider(room.client))
          .execute(
            roomId: room.id,
            baseUrl: baseUrl,
            startedTitle: l10n.videoCallStartedTitle,
          );
    } on VideoCallException {
      if (mounted) TwakeSnackBar.show(context, l10n.failedToStartVideoCall);
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoCallBaseUrl = ref.watch(
      loginHomeserverSummaryProvider.select(
        (summary) => summary?.videoCallBaseUrl,
      ),
    );
    if (widget.controller.room == null ||
        videoCallBaseUrl == null ||
        !widget.controller.canStartVideoCall(videoCallBaseUrl)) {
      return const SizedBox.shrink();
    }
    if (_isStarting) {
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
      tooltip: L10n.of(context)!.startVideoCall,
      onTap: () => unawaited(_start(videoCallBaseUrl)),
      preferBelow: false,
    );
  }
}
