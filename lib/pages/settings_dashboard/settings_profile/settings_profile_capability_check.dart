import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:flutter/widgets.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/profile_edit_capabilities_provider.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_user_info_provider.dart';

class SettingsProfileCapabilityCheck extends ConsumerWidget {
  const SettingsProfileCapabilityCheck({
    super.key,
    required this.builder,
    this.child,
    this.userId,
  });

  final Widget? child;
  final String? userId;
  final Widget Function(
    ProfileEditCapabilities? capabilities,
    UserInfo? userInfo,
    Widget? child,
  )
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = this.userId;
    return builder(
      ref.watch(profileEditCapabilitiesProvider).unwrapPrevious().value,
      userId == null
          ? null
          : ref.watch(settingsProfileUserInfoProvider(userId)).value,
      child,
    );
  }
}
