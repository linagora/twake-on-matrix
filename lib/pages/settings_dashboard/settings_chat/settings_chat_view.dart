import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar_style.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/settings_switch_list_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'settings_chat.dart';

class SettingsChatView extends StatelessWidget {
  final SettingsChatController controller;
  final responsive = getIt.get<ResponsiveUtils>();
  SettingsChatView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final isWebRTCSupported = Matrix.of(context).webrtcIsSupported;

    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: TwakeAppBar(
        title: l10n.chat,
        context: context,
        withDivider: true,
        centerTitle: true,
        leading: responsive.isMobile(context)
            ? Padding(
                padding: TwakeAppBarStyle.leadingIconPadding,
                child: IconButton(
                  tooltip: l10n.back,
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => context.pop(),
                  iconSize: TwakeAppBarStyle.leadingIconSize,
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: ListTileTheme(
        iconColor: Theme.of(context).textTheme.bodyLarge!.color,
        child: MaxWidthBody(
          withScrolling: true,
          child: Column(
            children: [
              SettingsSwitchListTile.adaptive(
                title: l10n.renderRichContent,
                onChanged: (b) => AppConfig.renderHtml = b,
                storeKey: SettingKeys.renderHtml,
                defaultValue: AppConfig.renderHtml,
              ),
              SettingsSwitchListTile.adaptive(
                title: l10n.hideRedactedEvents,
                onChanged: (b) => AppConfig.hideRedactedEvents = b,
                storeKey: SettingKeys.hideRedactedEvents,
                defaultValue: AppConfig.hideRedactedEvents,
              ),
              SettingsSwitchListTile.adaptive(
                title: l10n.hideUnknownEvents,
                onChanged: (b) => AppConfig.hideUnknownEvents = b,
                storeKey: SettingKeys.hideUnknownEvents,
                defaultValue: AppConfig.hideUnknownEvents,
              ),
              SettingsSwitchListTile.adaptive(
                title: l10n.hideUnimportantStateEvents,
                onChanged: (b) => AppConfig.hideUnimportantStateEvents = b,
                storeKey: SettingKeys.hideUnimportantStateEvents,
                defaultValue: AppConfig.hideUnimportantStateEvents,
              ),
              if (PlatformInfos.isMobile)
                SettingsSwitchListTile.adaptive(
                  title: l10n.autoplayImages,
                  onChanged: (b) => AppConfig.autoplayImages = b,
                  storeKey: SettingKeys.autoplayImages,
                  defaultValue: AppConfig.autoplayImages,
                ),
              if (!responsive.isMobile(context))
                SettingsSwitchListTile.adaptive(
                  title: l10n.enableRightAndLeftMessageAlignment,
                  onChanged: (value) =>
                      AppConfig.enableRightAndLeftMessageAlignmentOnWeb = value,
                  storeKey: SettingKeys.enableRightAndLeftMessageAlignmentOnWeb,
                  defaultValue:
                      AppConfig.enableRightAndLeftMessageAlignmentOnWeb,
                ),
              const Divider(),
              if (isWebRTCSupported)
                SettingsSwitchListTile.adaptive(
                  title: l10n.experimentalVideoCalls,
                  onChanged: (b) {
                    AppConfig.experimentalVoip = b;
                    Matrix.of(context).createVoipPlugin();
                    return;
                  },
                  storeKey: SettingKeys.experimentalVoip,
                  defaultValue: AppConfig.experimentalVoip,
                ),
              if (isWebRTCSupported && !kIsWeb)
                ListTile(
                  title: Text(l10n.callingPermissions),
                  trailing: const Padding(
                    padding: .all(16.0),
                    child: Icon(Icons.call),
                  ),
                ),
              // FIXME: This is temporary for short term objective: not support separated
            ],
          ),
        ),
      ),
    );
  }
}
