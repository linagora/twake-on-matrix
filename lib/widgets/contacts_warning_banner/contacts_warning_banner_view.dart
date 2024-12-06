import 'package:fluffychat/presentation/enum/contacts/warning_contacts_banner_enum.dart';
import 'package:fluffychat/widgets/contacts_warning_banner/contacts_warning_banner_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';

class ContactsWarningBannerView extends StatelessWidget {
  final ValueNotifier<WarningContactsBannerState> warningBannerNotifier;
  final bool isShowMargin;
  final Function()? closeContactsWarningBanner;
  final Function()? goToSettingsForPermissionActions;

  const ContactsWarningBannerView({
    super.key,
    required this.warningBannerNotifier,
    this.isShowMargin = true,
    this.closeContactsWarningBanner,
    this.goToSettingsForPermissionActions,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: warningBannerNotifier,
      builder: (context, state, child) {
        if (state == WarningContactsBannerState.display) {
          return Container(
            margin: isShowMargin
                ? ContactsWarningBannerStyle.marginWarningBanner
                : null,
            padding: ContactsWarningBannerStyle.paddingWarningBanner,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(
                  ContactsWarningBannerStyle.borderWarningBanner,
                ),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: ContactsWarningBannerStyle.paddingForContentBanner,
                  child: Text(
                    L10n.of(context)!.explainPermissionToAccessContacts,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: ContactsWarningBannerStyle.paddingRightButton,
                      child: TwakeTextButton(
                        onTap: closeContactsWarningBanner,
                        message: L10n.of(context)!.notNow,
                        borderHover: ContactsWarningBannerStyle
                            .borderHoverButtonWaningBanner,
                        styleMessage:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                        margin: ContactsWarningBannerStyle
                            .marginButtonWarningBanner,
                      ),
                    ),
                    TwakeTextButton(
                      message: L10n.of(context)!.next,
                      borderHover: ContactsWarningBannerStyle
                          .borderHoverButtonWaningBanner,
                      onTap: goToSettingsForPermissionActions,
                      styleMessage:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                      buttonDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      margin:
                          ContactsWarningBannerStyle.marginButtonWarningBanner,
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return child!;
      },
      child: const SizedBox.shrink(),
    );
  }
}
