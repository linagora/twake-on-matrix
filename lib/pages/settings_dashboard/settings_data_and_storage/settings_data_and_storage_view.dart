import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_style/settings_style_twake_view.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

import 'settings_data_and_storage.dart';
import 'settings_data_and_storage_constants.dart';

class SettingsDataAndStorageView extends StatelessWidget {
  final SettingsDataAndStorageController controller;

  const SettingsDataAndStorageView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final sysColors = LinagoraSysColors.material();
    final refColors = LinagoraRefColors.material();
    final textTheme = Theme.of(context).textTheme;

    final body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.phone_iphone,
                            size: 24,
                            color: sysColors.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.phoneStorage,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: sysColors.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.phoneStorageDescription(
                                    controller.storageUsagePercent,
                                  ),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: refColors.tertiary[30],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.storageUsagePercent,
                      style: textTheme.titleMedium?.copyWith(
                        color: sysColors.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: controller.isScanning
                        ? null
                        : controller.storageUsageRatio,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEEEEEE),
                    color: const Color(0xFF006DE2),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.twake,
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF636363),
                      ),
                    ),
                    Text(
                      l10n.available,
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF636363),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 48,
            color: sysColors.surfaceTint.withValues(alpha: 0.16),
          ),
          _StorageItem(
            refColors: refColors,
            sysColors: sysColors,
            icon: Icons.perm_media_outlined,
            label: l10n.medias,
            value: controller.formattedBytesFor(StorageCategory.medias),
          ),
          _StorageItem(
            refColors: refColors,
            sysColors: sysColors,
            icon: Icons.description_outlined,
            label: l10n.files,
            value: controller.formattedBytesFor(StorageCategory.files),
          ),
          _StorageItem(
            refColors: refColors,
            sysColors: sysColors,
            icon: Icons.smart_display_outlined,
            label: l10n.videos,
            value: controller.formattedBytesFor(StorageCategory.videos),
          ),
          _StorageItem(
            refColors: refColors,
            sysColors: sysColors,
            icon: Icons.sentiment_very_satisfied_outlined,
            label: l10n.stickersAndEmojis,
            value: controller.formattedBytesFor(StorageCategory.stickers),
          ),
          _StorageItem(
            refColors: refColors,
            sysColors: sysColors,
            icon: Icons.folder_outlined,
            label: l10n.other,
            value: controller.formattedBytesFor(StorageCategory.other),
            showDivider: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: FilledButton(
              onPressed: () => controller.onClearCache(context),
              style: FilledButton.styleFrom(
                backgroundColor: sysColors.primary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                l10n.clearCacheSize(controller.formattedTotalCache),
                style: textTheme.labelLarge?.copyWith(
                  color: sysColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final adaptiveBody = getIt.get<ResponsiveUtils>().isMobile(context)
        ? body
        : SettingsStyleTwakeView(child: body);

    return Scaffold(
      backgroundColor: sysColors.onPrimary,
      appBar: TwakeAppBar(
        context: context,
        title: l10n.dataAndStorage,
        withDivider: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24),
          onPressed: context.pop,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      ),
      body: adaptiveBody,
    );
  }
}

class _StorageItem extends StatelessWidget {
  final LinagoraRefColors refColors;
  final LinagoraSysColors sysColors;
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _StorageItem({
    required this.refColors,
    required this.sysColors,
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: refColors.tertiary[30]),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: refColors.neutral[10],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  color: refColors.neutral[10],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 41,
            color: sysColors.surfaceTint.withValues(alpha: 0.16),
          ),
      ],
    );
  }
}
