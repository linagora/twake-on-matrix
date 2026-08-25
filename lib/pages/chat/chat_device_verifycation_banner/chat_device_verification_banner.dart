import 'package:twake_chat/di/global/get_it_provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_device_verifycation_banner/chat_device_verification_banner_state.dart';
import 'package:twake_chat/pages/chat/chat_device_verifycation_banner/chat_device_verification_banner_view_model.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/banners/linagora_banner.dart';
import 'package:matrix/matrix.dart';

class ChatDeviceVerificationBanner extends ConsumerWidget {
  final Client client;

  const ChatDeviceVerificationBanner({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = chatDeviceVerificationBannerViewModelProvider(client);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    if (state is DisplayWarningBannerState) {
      // TODO(TW-3218 part II): wire the Verify action to the self-verification
      // flow for the current session (cross-signing via recovery key, not
      // device-to-device SAS verification). Action hidden until then.
      final responsive = ref.read(getItProvider).get<ResponsiveUtils>();
      final isMobile = responsive.isMobile(context);
      return LinagoraBanner(
        message: L10n.of(context)!.deviceVerificationWaring,
        onDismiss: isMobile ? null : controller.onDismissBanner,
      );
    }
    return const SizedBox.shrink();
  }
}
