import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_video_call_view_model.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

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
    final room = controller.room;
    if (room == null ||
        videoCallBaseUrl == null ||
        !controller.canStartVideoCall(videoCallBaseUrl)) {
      return const SizedBox.shrink();
    }
    final viewModelProvider = chatVideoCallViewModelProvider(
      client: room.client,
      roomId: room.id,
    );
    ref.listen(viewModelProvider, (_, next) {
      if (next is AsyncError) {
        TwakeSnackBar.show(context, L10n.of(context)!.failedToStartVideoCall);
      }
    });
    if (ref.watch(viewModelProvider).isLoading) {
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
      onTap: () => ref
          .read(viewModelProvider.notifier)
          .start(
            baseUrl: videoCallBaseUrl,
            startedTitle: L10n.of(context)!.videoCallStartedTitle,
          ),
      preferBelow: false,
    );
  }
}
