import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/chat_device_verifycation_banner/chat_device_verification_banner_state.dart';
import 'package:fluffychat/pages/chat/chat_device_verifycation_banner/chat_device_verification_banner_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/banners/linagora_banner.dart';
import 'package:matrix/matrix.dart';

class ChatDeviceVerificationBanner extends ConsumerWidget {
  final Room room;

  const ChatDeviceVerificationBanner({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = chatDeviceVerificationBannerViewModelProvider(room);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    if (state is DisplayWarningBannerState) {
      return LinagoraBanner(
        message: L10n.of(context)!.deviceVerificationWaring,
        actionLabel: L10n.of(context)!.verify,
        onActionPressed: () {},
        onDismiss: controller.onDismissBanner,
      );
    }
    return const SizedBox.shrink();
  }
}
