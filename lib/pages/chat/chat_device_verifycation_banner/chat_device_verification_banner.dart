import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/di/global/get_it_provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/bootstrap/bootstrap_dialog.dart';
import 'package:twake_chat/pages/chat/chat_device_verifycation_banner/chat_device_verification_banner_state.dart';
import 'package:twake_chat/pages/chat/chat_device_verifycation_banner/chat_device_verification_banner_view_model.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/banners/linagora_banner.dart';
import 'package:matrix/matrix.dart';

class ChatDeviceVerificationBanner extends ConsumerWidget {
  final Client client;

  final VoidCallback? onRequestUndecryptedMessagesRetry;

  const ChatDeviceVerificationBanner({
    super.key,
    required this.client,
    this.onRequestUndecryptedMessagesRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = chatDeviceVerificationBannerViewModelProvider(client);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    if (state is DisplayWarningBannerState) {
      final responsive = ref.read(getItProvider).get<ResponsiveUtils>();
      final isMobile = responsive.isMobile(context);
      return LinagoraBanner(
        message: L10n.of(context)!.deviceVerificationWaring,
        actionLabel: L10n.of(context)!.verify,
        onActionPressed: () async {
          if (state.isCurrentSessionOutOfSync) {
            await BootstrapDialog(client: client).show();
          } else {
            await const DevicesRoute().push(context);
          }
          onRequestUndecryptedMessagesRetry?.call();
        },
        onDismiss: isMobile ? null : controller.onDismissBanner,
      );
    }
    return const SizedBox.shrink();
  }
}
