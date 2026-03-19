import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_app_language/settings_app_language.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_app_language/settings_app_language_view_style.dart';
import 'package:fluffychat/presentation/extensions/localizations/locale_extension.dart';
import 'package:fluffychat/utils/extension/string_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SettingsAppLanguageView extends StatelessWidget {
  final SettingsAppLanguageController controller;
  final ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  SettingsAppLanguageView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: TwakeAppBar(
        title: l10n.appLanguage,
        context: context,
        leading: responsiveUtils.isMobile(context)
            ? Padding(
                padding: TwakeAppBarStyle.leadingIconPadding,
                child: IconButton(
                  tooltip: l10n.back,
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: context.pop,
                  iconSize: TwakeAppBarStyle.leadingIconSize,
                ),
              )
            : const SizedBox.shrink(),
        centerTitle: true,
        withDivider: true,
      ),
      body: SingleChildScrollView(
        padding: SettingsAppLanguageViewStyle.paddingBody,
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            ListView.separated(
              padding: SettingsAppLanguageViewStyle.paddingListItems,
              shrinkWrap: true,
              itemBuilder: (_, int index) {
                return ValueListenableBuilder(
                  valueListenable: controller.currentLocale,
                  builder: (context, locale, _) {
                    return ListTile(
                      splashColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          SettingsAppLanguageViewStyle.borderRadius,
                        ),
                      ),
                      title: Text(
                        controller.supportedLocales[index]
                            .getLanguageNameByCurrentLocale(context)
                            .capitalize(),
                        style: textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        controller.supportedLocales[index]
                            .getSourceLanguageName(),
                        style: textTheme.bodySmall!.copyWith(
                          color: LinagoraRefColors.material().neutral[40],
                        ),
                      ),
                      trailing:
                          controller.supportedLocales[index].languageCode ==
                              locale.languageCode
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.secondary,
                              size: SettingsAppLanguageViewStyle.iconSize,
                            )
                          : null,
                      onTap: () {
                        controller.changeLanguage(
                          controller.supportedLocales[index],
                        );
                      },
                    );
                  },
                );
              },
              separatorBuilder: (_, _) => const Divider(),
              itemCount: controller.supportedLocales.length,
            ),
          ],
        ),
      ),
    );
  }
}
