import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_item_builder.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_view_style.dart';
import 'package:fluffychat/presentation/enum/settings/settings_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'settings.dart';

class SettingsView extends StatelessWidget {
  final SettingsController controller;
  final Widget? bottomNavigationBar;
  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  const SettingsView(this.controller, {super.key, this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final sysColor = LinagoraSysColors.material();
    final refColorTertiary30 = LinagoraRefColors.material().tertiary[30];
    final theme = Theme.of(context);
    final appbarTheme = theme.appBarTheme;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: sysColor.onPrimary,
      appBar: TwakeAppBar(
        title: l10n.settings,
        withDivider: responsiveUtils.isMobile(context),
        context: context,
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: ListTileTheme(
        // TODO: change to colorSurface when its approved
        // ignore: deprecated_member_use
        iconColor: colorScheme.onBackground,
        child: ListView(
          key: const Key('SettingsListViewContent'),
          children: <Widget>[
            Padding(
              padding: SettingsViewStyle.bodySettingsScreenPadding,
              child: Material(
                borderRadius: .circular(SettingsViewStyle.borderRadius),
                clipBehavior: .hardEdge,
                color:
                    controller.optionsSelectNotifier.value ==
                        SettingEnum.profile
                    ? colorScheme.secondaryContainer
                    : sysColor.onPrimary,
                child: InkWell(
                  onTap: controller.goToSettingsProfile,
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
                                elevation:
                                    appbarTheme.scrolledUnderElevation ?? 4,
                                shadowColor: appbarTheme.shadowColor,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: theme.dividerColor),
                                  borderRadius: .circular(
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
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: .center,
                                  crossAxisAlignment: .start,
                                  children: [
                                    ValueListenableBuilder(
                                      valueListenable:
                                          controller.displayNameNotifier,
                                      builder: (context, displayName, _) {
                                        return Text(
                                          displayName ?? controller.displayName,
                                          style: textTheme.titleLarge?.copyWith(
                                            color: colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                    Text(
                                      controller.client.mxid(context),
                                      style: textTheme.labelLarge?.copyWith(
                                        color: refColorTertiary30,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_outlined,
                                size: SettingsViewStyle.iconSize,
                                color: refColorTertiary30,
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
            Padding(
              padding: SettingsViewStyle.profileItemDividerPadding(context),
              child: Divider(
                color: LinagoraStateLayer(sysColor.surfaceTint).opacityLayer3,
                thickness: SettingsViewStyle.settingsItemDividerThickness,
                height: SettingsViewStyle.settingsItemDividerHeight,
              ),
            ),
            if (!controller.matrix.twakeSupported)
              ValueListenableBuilder(
                valueListenable: controller.showChatBackupSwitch,
                builder: (_, backUpAvailable, _) {
                  return SwitchListTile(
                    controlAffinity: .trailing,
                    contentPadding: SettingsViewStyle.backupSwitchPadding,
                    value: backUpAvailable == false,
                    secondary: const Icon(Icons.backup_outlined),
                    title: Text(l10n.chatBackup),
                    onChanged: controller.firstRunBootstrapAction,
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(l10n.chatBackup),
                  trailing: const CircularProgressIndicator.adaptive(),
                ),
              ),
            Column(
              children: controller.getListSettingItem.map((SettingEnum item) {
                return Column(
                  children: [
                    Padding(
                      padding: SettingsViewStyle.bodySettingsScreenPadding,
                      child: SettingsItemBuilder(
                        key: Key(item.name),
                        title: item.titleSettings(context),
                        titleColor: item.titleColor(context),
                        leading: item.iconLeading(),
                        onTap: () => controller.onClickToSettingsItem(item),
                        isHideTrailingIcon: item.isHideTrailingIcon,
                        leadingIconColor: item.iconColor(context),
                        isSelected: controller.optionSelected(item),
                      ),
                    ),
                    item.index == SettingEnum.deleteAccount.index
                        ? const SizedBox()
                        : Padding(
                            padding:
                                SettingsViewStyle.settingsItemDividerPadding(),
                            child: Divider(
                              color: LinagoraStateLayer(
                                sysColor.surfaceTint,
                              ).opacityLayer3,
                              thickness: SettingsViewStyle
                                  .settingsItemDividerThickness,
                              height:
                                  SettingsViewStyle.settingsItemDividerHeight,
                            ),
                          ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
