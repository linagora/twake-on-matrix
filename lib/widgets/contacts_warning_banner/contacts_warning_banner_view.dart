import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/presentation/enum/contacts/warning_contacts_banner_enum.dart';
import 'package:fluffychat/widgets/contacts_warning_banner/contacts_warning_banner_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';

class ContactsWarningBannerView extends StatelessWidget {
  final ValueNotifier<WarningContactsBannerState> warningBannerNotifier;
  final bool isShowMargin;

  const ContactsWarningBannerView({
    super.key,
    required this.warningBannerNotifier,
    this.isShowMargin = true,
  });

  @override
  Widget build(BuildContext context) {
    final contactsManager = getIt.get<ContactsManager>();
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
                        onTap: contactsManager.closeContactsWarningBanner,
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
                      message: L10n.of(context)!.allow,
                      borderHover: ContactsWarningBannerStyle
                          .borderHoverButtonWaningBanner,
                      onTap: contactsManager.goToSettingsForPermissionActions,
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
