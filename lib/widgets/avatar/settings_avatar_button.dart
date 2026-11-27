import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

/// The avatar of the user at the start of the phone app bars: it opens
/// Settings, which is no tab of the bottom bar.
class SettingsAvatarButton extends ConsumerWidget {
  /// Reads the profile of the active account.
  const SettingsAvatarButton({super.key, required this.onTap})
    : _given = false,
      avatarUrl = null,
      name = null;

  /// The profile the app bar already follows.
  const SettingsAvatarButton.of({
    super.key,
    required this.onTap,
    required this.avatarUrl,
    required this.name,
  }) : _given = true;

  final VoidCallback? onTap;
  final Uri? avatarUrl;
  final String? name;
  final bool _given;

  static const double size = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_given) {
      return _button(context, avatarUrl: this.avatarUrl, name: name);
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
