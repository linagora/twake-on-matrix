import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/utils/beautify_string_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'settings_security.dart';

class SettingsSecurityView extends StatelessWidget {
  final SettingsSecurityController controller;
  final responsive = getIt.get<ResponsiveUtils>();

  SettingsSecurityView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.security,
        context: context,
        centerTitle: true,
        withDivider: true,
        leading: responsive.isMobile(context)
            ? Padding(
                padding: TwakeAppBarStyle.leadingIconPadding,
                child: IconButton(
                  tooltip: L10n.of(context)!.back,
                  icon: const Icon(Icons.chevron_left_outlined),
                  onPressed: () => context.pop(),
                  iconSize: TwakeAppBarStyle.leadingIconSize,
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: ListTileTheme(
        // TODO: remove when the color scheme is updated
        // ignore: deprecated_member_use
        iconColor: Theme.of(context).colorScheme.onBackground,
        child: MaxWidthBody(
          withScrolling: true,
          child: Column(
            children: [
              // #869 Hide privacy settings for now
              // ListTile(
              //   leading: const Icon(Icons.camera_outlined),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(L10n.of(context)!.whoCanSeeMyStories),
              //   onTap: () => context.go('/stories'),
              // ),
              // ListTile(
              //   leading: const Icon(Icons.block_outlined),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(L10n.of(context)!.ignoredUsers),
              //   onTap: () => context.go('/ignorelist'),
              // ),
              // ListTile(
              //   leading: const Icon(Icons.password_outlined),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(
              //     L10n.of(context)!.changePassword,
              //   ),
              //   onTap: controller.changePasswordAccountAction,
              // ),
              // ListTile(
              //   leading: const Icon(Icons.mail_outlined),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(L10n.of(context)!.passwordRecovery),
              //   onTap: () => context.go('/3pid'),
              // ),
              if (Matrix.of(context).client.encryption != null) ...{
                if (PlatformInfos.isMobile)
                  ListTile(
                    leading: const Icon(Icons.lock_outlined),
                    trailing: const Icon(Icons.chevron_right_outlined),
                    title: Text(L10n.of(context)!.appLock),
                    onTap: controller.setAppLockAction,
                  ),
                ListTile(
                  title: Text(L10n.of(context)!.yourPublicKey),
                  subtitle: Text(
                    Matrix.of(context).client.fingerprintKey.beautified,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  leading: const Icon(Icons.vpn_key_outlined),
                  trailing: InkWell(
                    onTap: controller.copyPublicKey,
                    child: const Icon(Icons.content_copy),
                  ),
                ),
              },
              //TODO #1734: Remove dehydrate and delete account
              // ListTile(
              //   leading: const Icon(Icons.tap_and_play),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(
              //     L10n.of(context)!.dehydrate,
              //     style: const TextStyle(color: Colors.red),
              //   ),
              //   onTap: controller.dehydrateAction,
              // ),
              // ListTile(
              //   leading: const Icon(Icons.delete_outlined),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(
              //     L10n.of(context)!.deleteAccount,
              //     style: const TextStyle(color: Colors.red),
              //   ),
              //   onTap: controller.deleteAccountAction,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
