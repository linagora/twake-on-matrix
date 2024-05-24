import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_item_builder.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_view_style.dart';
import 'package:fluffychat/presentation/enum/settings/settings_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'settings.dart';

class SettingsView extends StatelessWidget {
  final SettingsController controller;
  final Widget? bottomNavigationBar;

  const SettingsView(
    this.controller, {
    super.key,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: AppBar(
        backgroundColor: LinagoraSysColors.material().onPrimary,
        toolbarHeight: AppConfig.toolbarHeight(context),
        title: Align(
          alignment: SettingsViewStyle.alignment,
          child: Padding(
            padding: SettingsViewStyle.titlePadding,
            child: Text(
              L10n.of(context)!.settings,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: ListTileTheme(
        // TODO: change to colorSurface when its approved
        // ignore: deprecated_member_use
        iconColor: Theme.of(context).colorScheme.onBackground,
        child: ListView(
          key: const Key('SettingsListViewContent'),
          children: <Widget>[
            Padding(
              padding: SettingsViewStyle.bodySettingsScreenPadding,
              child: Material(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                clipBehavior: Clip.hardEdge,
                color: controller.optionsSelectNotifier.value ==
                        SettingEnum.profile
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : LinagoraSysColors.material().onPrimary,
                child: InkWell(
                  onTap: () => controller.goToSettingsProfile(),
                  child: Padding(
                    padding: SettingsViewStyle.itemBuilderPadding,
                    child: Row(
                      children: [
                        ValueListenableBuilder(
                          valueListenable: controller.avatarUriNotifier,
                          builder: (context, avatarUrl, __) {
                            return Padding(
                              padding: SettingsViewStyle.avatarPadding,
                              child: Material(
                                elevation: Theme.of(context)
                                        .appBarTheme
                                        .scrolledUnderElevation ??
                                    4,
                                shadowColor:
                                    Theme.of(context).appBarTheme.shadowColor,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AvatarStyle.defaultSize,
                                  ),
                                ),
                                child: Avatar(
                                  mxContent: avatarUrl,
                                  name: controller.displayName,
                                  size: AvatarStyle.defaultSize,
                                  fontSize: SettingsViewStyle.fontSizeAvatar,
                                ),
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ValueListenableBuilder(
                                      valueListenable:
                                          controller.displayNameNotifier,
                                      builder: (context, displayName, _) {
                                        return Text(
                                          displayName ?? controller.displayName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                    Text(
                                      controller.client.mxid(context),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: LinagoraRefColors.material()
                                                .neutral[40],
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_outlined,
                                size: SettingsViewStyle.iconSize,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
            if (!controller.matrix.twakeSupported)
              ValueListenableBuilder(
                valueListenable: controller.showChatBackupSwitch,
                builder: (context, backUpAvailable, child) {
                  return SwitchListTile(
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: SettingsViewStyle.backupSwitchPadding,
                    value: backUpAvailable == false,
                    secondary: const Icon(Icons.backup_outlined),
                    title: Text(L10n.of(context)!.chatBackup),
                    onChanged: controller.firstRunBootstrapAction,
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(L10n.of(context)!.chatBackup),
                  trailing: const CircularProgressIndicator.adaptive(),
                ),
              ),
            Column(
              children: controller.getListSettingItem.map((item) {
                return Padding(
                  padding: SettingsViewStyle.bodySettingsScreenPadding,
                  child: SettingsItemBuilder(
                    title: item.titleSettings(context),
                    subtitle: item.subtitleSettings(context),
                    leading: item.iconLeading(),
                    onTap: () => controller.onClickToSettingsItem(item),
                    isHideTrailingIcon: item.isHideTrailingIcon,
                    isSelected: controller.optionSelected(item),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
