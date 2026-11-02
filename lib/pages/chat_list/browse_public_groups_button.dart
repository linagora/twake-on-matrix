import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list_header_style.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_page.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/widgets/twake_cupertino_page.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

class BrowsePublicGroupsButton extends ConsumerWidget {
  const BrowsePublicGroupsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(
      loginHomeserverSummaryProvider.select(
        (summary) => summary.isPublicGroupsEnabled,
      ),
    );
    if (!isEnabled) return const SizedBox.shrink();
    return TwakeIconButton(
      tooltip: L10n.of(context)!.browsePublicGroups,
      imagePath: Assets.images.icPlanet.path,
      imageSize: ChatListHeaderStyle.searchIconSize,
      iconColor: LinagoraRefColors.material().neutral[60],
      onTap: () => unawaited(
        Navigator.of(context).push(
          TwakeCupertinoPageRoute(builder: (_) => const PublicRoomsPage()),
        ),
      ),
    );
  }
}
