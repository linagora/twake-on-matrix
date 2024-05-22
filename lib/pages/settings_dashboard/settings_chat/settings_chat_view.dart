import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_app_bar.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/voip/callkeep_manager.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/settings_switch_list_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'settings_chat.dart';

class SettingsChatView extends StatelessWidget {
  final SettingsChatController controller;
  const SettingsChatView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: SettingsAppBar(
        title: Text(L10n.of(context)!.chat),
        context: context,
      ),
      body: ListTileTheme(
        iconColor: Theme.of(context).textTheme.bodyLarge!.color,
        child: MaxWidthBody(
          withScrolling: true,
          child: Column(
            children: [
              const Divider(),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context)!.renderRichContent,
                onChanged: (b) => AppConfig.renderHtml = b,
                storeKey: SettingKeys.renderHtml,
                defaultValue: AppConfig.renderHtml,
              ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context)!.hideRedactedEvents,
                onChanged: (b) => AppConfig.hideRedactedEvents = b,
                storeKey: SettingKeys.hideRedactedEvents,
                defaultValue: AppConfig.hideRedactedEvents,
              ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context)!.hideUnknownEvents,
                onChanged: (b) => AppConfig.hideUnknownEvents = b,
                storeKey: SettingKeys.hideUnknownEvents,
                defaultValue: AppConfig.hideUnknownEvents,
              ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context)!.hideUnimportantStateEvents,
                onChanged: (b) => AppConfig.hideUnimportantStateEvents = b,
                storeKey: SettingKeys.hideUnimportantStateEvents,
                defaultValue: AppConfig.hideUnimportantStateEvents,
              ),
              if (PlatformInfos.isMobile)
                SettingsSwitchListTile.adaptive(
                  title: L10n.of(context)!.autoplayImages,
                  onChanged: (b) => AppConfig.autoplayImages = b,
                  storeKey: SettingKeys.autoplayImages,
                  defaultValue: AppConfig.autoplayImages,
                ),
              const Divider(),
              if (Matrix.of(context).webrtcIsSupported)
                SettingsSwitchListTile.adaptive(
                  title: L10n.of(context)!.experimentalVideoCalls,
                  onChanged: (b) {
                    AppConfig.experimentalVoip = b;
                    Matrix.of(context).createVoipPlugin();
                    return;
                  },
                  storeKey: SettingKeys.experimentalVoip,
                  defaultValue: AppConfig.experimentalVoip,
                ),
              if (Matrix.of(context).webrtcIsSupported && !kIsWeb)
                ListTile(
                  title: Text(L10n.of(context)!.callingPermissions),
                  onTap: () =>
                      CallKeepManager().checkoutPhoneAccountSetting(context),
                  trailing: const Padding(
                    padding: EdgeInsets.all(16.0),
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
