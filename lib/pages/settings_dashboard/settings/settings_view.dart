import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_item_builder.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_view_style.dart';
import 'package:fluffychat/presentation/enum/settings/settings_enum.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

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
      appBar: AppBar(
        title: Text(
          L10n.of(context)!.settings,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: ListTileTheme(
        iconColor: Theme.of(context).colorScheme.onBackground,
        child: ListView(
          key: const Key('SettingsListViewContent'),
          children: <Widget>[
            Builder(
              builder: (context) {
                return ValueListenableBuilder(
                  valueListenable: controller
                      .settingsDashboardManagerController.profileNotifier,
                  builder: (context, profile, _) {
                    return Padding(
                      padding: SettingsViewStyle.bodySettingsScreenPadding,
                      child: Material(
                        borderRadius:
                            BorderRadius.circular(AppConfig.borderRadius),
                        clipBehavior: Clip.hardEdge,
                        color: controller.settingsDashboardManagerController
                                    .optionsSelectNotifier.value ==
                                SettingEnum.profile
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : null,
                        child: InkWell(
                          onTap: () => controller.goToSettingsProfile(profile),
                          child: Padding(
                            padding: SettingsViewStyle.itemBuilderPadding,
                            child: Row(
                              children: [
                                Padding(
                                  padding: SettingsViewStyle.avatarPadding,
                                  child: Stack(
                                    children: [
                                      Material(
                                        elevation: Theme.of(context)
                                                .appBarTheme
                                                .scrolledUnderElevation ??
                                            4,
                                        shadowColor: Theme.of(context)
                                            .appBarTheme
                                            .shadowColor,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color:
                                                Theme.of(context).dividerColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AvatarStyle.defaultSize,
                                          ),
                                        ),
                                        child: Avatar(
                                          mxContent: profile.avatarUrl,
                                          name: controller.displayName,
                                          size: AvatarStyle.defaultSize,
                                          fontSize:
                                              SettingsViewStyle.fontSizeAvatar,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile.displayName ??
                                                  controller.displayName,
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
                                            ),
                                            Text(
                                              controller.mxid,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    color: LinagoraRefColors
                                                            .material()
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
                    );
                  },
                );
              },
            ),
            const Divider(thickness: 1),
            Column(
              children: controller.getListSettingItem().map((item) {
                return Padding(
                  padding: SettingsViewStyle.bodySettingsScreenPadding,
                  child: SettingsItemBuilder(
                    title: item.titleSettings(context),
                    subtitle: item.subtitleSettings(context),
                    leading: item.iconLeading(),
                    onTap: () => controller.onClickToSettingsItem(item),
                    isHideTrailingIcon: item.isHideTrailingIcon,
                    isSelected: controller.settingsDashboardManagerController
                        .optionSelected(item),
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
