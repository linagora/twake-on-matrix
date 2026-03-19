import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';

import 'settings_style_view.dart';

class SettingsStyle extends StatefulWidget {
  const SettingsStyle({super.key});

  @override
  SettingsStyleController createState() => SettingsStyleController();
}

class SettingsStyleController extends State<SettingsStyle> {
  void setWallpaperAction() async {
    final picked = await FilePicker.platform.pickFiles(type: .image);
    final pickedFile = picked?.files.firstOrNull;

    if (pickedFile == null) return;
    await matrix.store.setItem(SettingKeys.wallpaper, pickedFile.path);
    setState(() {});
  }

  void deleteWallpaperAction() async {
    matrix.wallpaper = null;
    await matrix.store.deleteItem(SettingKeys.wallpaper);
    setState(() {});
  }

  void setChatColor(Color? color) async {
    if (color != null) {
      AppConfig.colorSchemeSeed = color;
    }
    controller.setPrimaryColor(color);
  }

  MatrixState get matrix => Matrix.of(context);
  ThemeController get controller => ThemeController.of(context);
  ThemeMode get currentTheme => controller.themeMode;
  Color? get currentColor => controller.primaryColor;

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
      case .light:
        controller.setThemeMode(.light);
        break;
      case .dark:
        controller.setThemeMode(.dark);
        break;
      case .system:
        controller.setThemeMode(.system);
        break;
    }
    setState(() {});
  }

  void changeFontSizeFactor(double d) {
    setState(() => AppConfig.fontSizeFactor = d);
    matrix.store.setItem(
      SettingKeys.fontSizeFactor,
      AppConfig.fontSizeFactor.toString(),
    );
  }

  void changeBubbleSizeFactor(double d) {
    setState(() => AppConfig.bubbleSizeFactor = d);
    matrix.store.setItem(
      SettingKeys.bubbleSizeFactor,
      AppConfig.bubbleSizeFactor.toString(),
    );
  }

  @override
  Widget build(_) => SettingsStyleView(this);
}
