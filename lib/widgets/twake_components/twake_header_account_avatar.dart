import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/avatar/linagora_presence_badge.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/extensions/person_presence_extension.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/twake_components/twake_header_style.dart';

/// The avatar of the active account, which opens the settings.
class TwakeHeaderAccountAvatar extends ConsumerWidget {
  const TwakeHeaderAccountAvatar({
    super.key,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.onTap,
  });

  final String userId;
  final String? name;
  final Uri? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = userId.isEmpty
        ? null
        : ref.watch(personPresenceProvider(userId)).value;
    return Semantics(
      button: true,
      label: L10n.of(context)!.settings,
      child: InkWell(
        key: NavigationKeys.accountAvatar.key,
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: TwakeHeaderStyle.accountAvatarTapTarget,
          child: ExcludeSemantics(
            child: Center(
              child: LinagoraPresenceBadge(
                presence: presence?.badge,
                size: TwakeHeaderStyle.avatarSize,
                child: Avatar(
                  mxContent: avatarUrl,
                  name: name,
                  size: TwakeHeaderStyle.avatarSize,
                  fontSize: TwakeHeaderStyle.avatarFontSizeInAppBar,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
