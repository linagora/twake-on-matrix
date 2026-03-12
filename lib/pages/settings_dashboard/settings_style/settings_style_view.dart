import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'settings_style.dart';

class SettingsStyleView extends StatelessWidget {
  final SettingsStyleController controller;

  const SettingsStyleView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    const colorPickerSize = 32.0;
    final wallpaper = Matrix.of(context).wallpaper;
    final onPrimary = LinagoraSysColors.material().onPrimary;
    final l10n = L10n.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: onPrimary,
      appBar: AppBar(
        backgroundColor: onPrimary,
        leading: const BackButton(),
        title: Text(l10n.changeTheme),
      ),
      body: MaxWidthBody(
        withScrolling: true,
        child: Column(
          children: [
            SizedBox(
              height: colorPickerSize + 24,
              child: ListView(
                shrinkWrap: true,
                scrollDirection: .horizontal,
                children: SettingsStyleController.customColors
                    .map(
                      (color) => Padding(
                        padding: const .all(12.0),
                        child: InkWell(
                          borderRadius: .circular(colorPickerSize),
                          onTap: () => controller.setChatColor(color),
                          child: color == null
                              ? Material(
                                  elevation: 0,
                                  borderRadius: .circular(colorPickerSize),
                                  child: Image.asset(
                                    'assets/colors.png',
                                    width: colorPickerSize,
                                    height: colorPickerSize,
                                  ),
                                )
                              : Material(
                                  color: color,
                                  elevation: 6,
                                  borderRadius: .circular(colorPickerSize),
                                  child: SizedBox(
                                    width: colorPickerSize,
                                    height: colorPickerSize,
                                    child: controller.currentColor == color
                                        ? const Center(
                                            child: Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            RadioListTile<ThemeMode>(
              groupValue: controller.currentTheme,
              value: .system,
              title: Text(l10n.systemTheme),
              onChanged: controller.switchTheme,
            ),
            RadioListTile<ThemeMode>(
              groupValue: controller.currentTheme,
              value: .light,
              title: Text(l10n.lightTheme),
              onChanged: controller.switchTheme,
            ),
            RadioListTile<ThemeMode>(
              groupValue: controller.currentTheme,
              value: .dark,
              title: Text(l10n.darkTheme),
              onChanged: controller.switchTheme,
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(
                l10n.wallpaper,
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontWeight: .bold,
                ),
              ),
            ),
            if (wallpaper != null)
              ListTile(
                title: Image.file(wallpaper, height: 38, fit: .cover),
                trailing: const Icon(Icons.delete_outlined, color: Colors.red),
                onTap: controller.deleteWallpaperAction,
              ),
            Builder(
              builder: (context) {
                return ListTile(
                  title: Text(l10n.changeWallpaper),
                  trailing: Icon(
                    Icons.photo_outlined,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  onTap: controller.setWallpaperAction,
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(
                l10n.messages,
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontWeight: .bold,
                ),
              ),
            ),
            Container(
              alignment: .centerLeft,
              padding: const .symmetric(horizontal: 12),
              child: Material(
                color: colorScheme.primary,
                elevation: 6,
                shadowColor: theme.secondaryHeaderColor.withAlpha(100),
                borderRadius: .circular(AppConfig.borderRadius),
                child: Padding(
                  padding: .all(16 * AppConfig.bubbleSizeFactor),
                  child: Text(
                    'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize:
                          AppConfig.messageFontSize * AppConfig.fontSizeFactor,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text(l10n.fontSize),
              trailing: Text('× ${AppConfig.fontSizeFactor}'),
            ),
            Slider.adaptive(
              min: 0.5,
              max: 2.5,
              divisions: 20,
              value: AppConfig.fontSizeFactor,
              semanticFormatterCallback: (d) => d.toString(),
              onChanged: controller.changeFontSizeFactor,
            ),
            ListTile(
              title: Text(l10n.bubbleSize),
              trailing: Text('× ${AppConfig.bubbleSizeFactor}'),
            ),
            Slider.adaptive(
              min: 0.5,
              max: 1.5,
              divisions: 4,
              value: AppConfig.bubbleSizeFactor,
              semanticFormatterCallback: (d) => d.toString(),
              onChanged: controller.changeBubbleSizeFactor,
            ),
          ],
        ),
      ),
    );
  }
}
