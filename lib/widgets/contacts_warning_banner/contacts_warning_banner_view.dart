import 'package:fluffychat/widgets/contacts_warning_banner/contacts_warning_banner_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';

class ContactsWarningBannerView extends StatelessWidget {
  final ValueNotifier<bool> isShowContactsWarningBannerNotifier;
  final Function()? onCloseContactsWarningBanner;
  final Function()? onGoToSettingsForPermissionActions;

  const ContactsWarningBannerView({
    super.key,
    required this.isShowContactsWarningBannerNotifier,
    this.onCloseContactsWarningBanner,
    this.onGoToSettingsForPermissionActions,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isShowContactsWarningBannerNotifier,
      builder: (context, isShowContactsWarningBanner, child) {
        if (!isShowContactsWarningBanner) {
          return child!;
        }
        return Container(
          margin: ContactsWarningBannerStyle.marginWarningBanner,
          padding: ContactsWarningBannerStyle.paddingWarningBanner,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(ContactsWarningBannerStyle.borderWarningBanner),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: ContactsWarningBannerStyle.paddingForContentBanner,
                child: Text(
                  L10n.of(context)!.contactsWarningBannerTitle,
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
                      onTap: onCloseContactsWarningBanner,
                      message: L10n.of(context)!.notNow,
                      borderHover: ContactsWarningBannerStyle
                          .borderHoverButtonWaningBanner,
                      styleMessage:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      margin:
                          ContactsWarningBannerStyle.marginButtonWarningBanner,
                    ),
                  ),
                  TwakeTextButton(
                    message: L10n.of(context)!.allow,
                    borderHover: ContactsWarningBannerStyle
                        .borderHoverButtonWaningBanner,
                    onTap: onGoToSettingsForPermissionActions,
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
      },
      child: const SizedBox.shrink(),
    );
  }
}
