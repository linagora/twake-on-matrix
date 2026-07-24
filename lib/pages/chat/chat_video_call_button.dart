import 'package:fluffychat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/providers/login_homeserver_summary_provider.dart';
import 'package:fluffychat/utils/voip/video_call_helper.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class ChatVideoCallButton extends ConsumerWidget {
  final ChatController controller;

  const ChatVideoCallButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoCallBaseUrl = ref.watch(
      loginHomeserverSummaryProvider.select(
        (summary) => summary?.videoCallBaseUrl,
      ),
    );
    if (!controller.canStartVideoCall(videoCallBaseUrl)) {
      return const SizedBox.shrink();
    }
    return TwakeIconButton(
      icon: Icons.videocam_outlined,
      tooltip: L10n.of(context)!.startVideoCall,
      onTap: () => VideoCallHelper.start(
        room: controller.room,
        startedTitle: L10n.of(context)!.videoCallStartedTitle,
        baseUrl: videoCallBaseUrl,
      ),
      preferBelow: false,
    );
  }
}
