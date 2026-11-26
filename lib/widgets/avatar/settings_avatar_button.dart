import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart' show Profile;
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

/// The avatar of the user at the start of the phone app bars: it opens
/// Settings, which is no tab of the bottom bar.
class SettingsAvatarButton extends ConsumerWidget {
  const SettingsAvatarButton({super.key, required this.onTap, this.profile});

  final VoidCallback? onTap;

  /// The profile of the user when the app bar already follows it; read from
  /// the active account otherwise.
  final ValueListenable<Profile>? profile;

  static const double size = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = this.profile;
    if (profile != null) {
      return ValueListenableBuilder(
        valueListenable: profile,
        builder: (context, profile, _) => _button(
          context,
          avatarUrl: profile.avatarUrl,
          name: profile.displayName ?? profile.userId,
        ),
      );
    }
    final userId = ref.watch(activeUserIdProvider);
    final fetched = userId == null
        ? null
        : ref.watch(matrixUserProfileProvider(userId)).value;
    final avatarUrl = fetched?.avatarUrl;
    return _button(
      context,
      avatarUrl: avatarUrl == null ? null : Uri.tryParse(avatarUrl),
      name: fetched?.displayName ?? userId,
    );
  }

  Widget _button(BuildContext context, {Uri? avatarUrl, String? name}) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: L10n.of(context)!.settings,
        child: InkWell(
          key: NavigationKeys.settingsAvatar.key,
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: ExcludeSemantics(
              child: Avatar(mxContent: avatarUrl, name: name, size: size),
            ),
          ),
        ),
      ),
    );
  }
}
