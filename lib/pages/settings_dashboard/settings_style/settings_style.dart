import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import 'settings_style_view.dart';

class SettingsStyle extends StatefulWidget {
  const SettingsStyle({super.key});

  @override
  SettingsStyleController createState() => SettingsStyleController();
}

class SettingsStyleController extends State<SettingsStyle> {
  void setWallpaperAction() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final pickedFile = picked?.files.firstOrNull;

    if (pickedFile == null) return;
    await Matrix.of(context)
        .store
        .setItem(SettingKeys.wallpaper, pickedFile.path);
    setState(() {});
  }

  void deleteWallpaperAction() async {
    Matrix.of(context).wallpaper = null;
    await Matrix.of(context).store.deleteItem(SettingKeys.wallpaper);
    setState(() {});
  }

  void setChatColor(Color? color) async {
    if (color != null) {
      AppConfig.colorSchemeSeed = color;
      ThemeController.of(context).setPrimaryColor(color);
    }
  }

  ThemeMode get currentTheme => ThemeController.of(context).themeMode;
  Color? get currentColor => ThemeController.of(context).primaryColor;

  static final List<Color?> customColors = [
    AppConfig.chatColor,
    Colors.blue.shade800,
    Colors.green.shade800,
    Colors.orange.shade700,
    Colors.pink.shade700,
    Colors.blueGrey.shade600,
    null,
  ];

  void switchTheme(ThemeMode? newTheme) {
    if (newTheme == null) return;
    switch (newTheme) {
      case ThemeMode.light:
        ThemeController.of(context).setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.dark:
        ThemeController.of(context).setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.system:
        ThemeController.of(context).setThemeMode(ThemeMode.system);
        break;
    }
    setState(() {});
  }

  void changeFontSizeFactor(double d) {
    setState(() => AppConfig.fontSizeFactor = d);
    Matrix.of(context).store.setItem(
          SettingKeys.fontSizeFactor,
          AppConfig.fontSizeFactor.toString(),
        );
  }

  void changeBubbleSizeFactor(double d) {
    setState(() => AppConfig.bubbleSizeFactor = d);
    Matrix.of(context).store.setItem(
          SettingKeys.bubbleSizeFactor,
          AppConfig.bubbleSizeFactor.toString(),
        );
  }

  @override
  Widget build(BuildContext context) => SettingsStyleView(this);
}
