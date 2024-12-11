import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/presentation/enum/contacts/warning_contacts_banner_enum.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_empty.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_failure.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_success.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ExpansionList extends StatelessWidget {
  final ValueNotifier<Either<Failure, Success>> presentationContactsNotifier;
  final ValueNotifier<bool> isShowContactsNotifier;
  final Function() goToNewGroupChat;
  final Function() toggleContactsList;
  final Function(BuildContext context, PresentationContact contact)
      onExternalContactTap;
  final Function(BuildContext context, PresentationContact contact)
      onContactTap;
  final TextEditingController textEditingController;
  final ValueNotifier<WarningContactsBannerState> warningBannerNotifier;
  final Function()? closeContactsWarningBanner;
  final Function()? goToSettingsForPermissionActions;

  const ExpansionList({
    super.key,
    required this.presentationContactsNotifier,
    required this.isShowContactsNotifier,
    required this.goToNewGroupChat,
    required this.toggleContactsList,
    required this.onExternalContactTap,
    required this.onContactTap,
    required this.textEditingController,
    required this.warningBannerNotifier,
    this.closeContactsWarningBanner,
    this.goToSettingsForPermissionActions,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: presentationContactsNotifier,
      builder: (context, state, child) {
        return state.fold(
          (failure) {
            final textControllerIsEmpty = textEditingController.text.isEmpty;
            if (failure is GetPresentationContactsEmpty ||
                failure is GetPresentationContactsFailure) {
              return Column(
                children: [
                  ..._buildResponsiveButtons(context),
                  const SizedBox(
                    height: 12,
                  ),
                  NoContactsFound(
                    keyword: textControllerIsEmpty
                        ? null
                        : textEditingController.text,
                  ),
                ],
              );
            }
            return child!;
          },
          (success) {
            if (success is ContactsLoading) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._buildResponsiveButtons(context),
                  const LoadingContactWidget(),
                ],
              );
            }

            if (success is PresentationExternalContactSuccess) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._buildResponsiveButtons(context),
                  TwakeInkWell(
                    onTap: () {
                      onContactTap(
                        context,
                        success.contact,
                      );
                    },
                    child: ExpansionContactListTile(
                      contact: success.contact,
                      highlightKeyword: textEditingController.text,
                    ),
                  ),
                ],
              );
            }

            if (success is PresentationContactsSuccess) {
              final textControllerIsEmpty = textEditingController.text.isEmpty;
              final contacts = success.contacts;
              if (!textControllerIsEmpty && contacts.isEmpty) {
                return Column(
                  children: [
                    const SizedBox(
                      height: 12,
                    ),
                    NoContactsFound(
                      keyword: textEditingController.text,
                    ),
                    ..._buildResponsiveButtons(context),
                  ],
                );
              }

              final expansionList = [
                const SizedBox(
                  height: 4,
                ),
                _buildTitle(context, contacts.length),
                ValueListenableBuilder<bool>(
                  valueListenable: isShowContactsNotifier,
                  builder: ((context, isShow, child) {
                    if (!isShow) {
                      return const SizedBox.shrink();
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        return TwakeInkWell(
                          onTap: () {
                            onContactTap(
                              context,
                              contacts[index],
                            );
                          },
                          child: ExpansionContactListTile(
                            contact: contacts[index],
                            highlightKeyword: textEditingController.text,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ];

              return Column(
                children: [
                  if (textControllerIsEmpty) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    ..._buildResponsiveButtons(context),
                    for (final child in expansionList) ...[child],
                  ] else ...[
                    for (final child in expansionList) ...[child],
                    ..._buildResponsiveButtons(context),
                  ],
                ],
              );
            }

            return child!;
          },
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildResponsiveButtons(context),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, int countContacts) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        children: [
          Text(
            L10n.of(context)!.twakeUsers,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: LinagoraRefColors.material().neutral[40],
                ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: isShowContactsNotifier,
                  builder: (context, isShow, child) {
                    return TwakeIconButton(
                      paddingAll: 6.0,
                      buttonDecoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      icon: isShow ? Icons.expand_less : Icons.expand_more,
                      onTap: toggleContactsList,
                      tooltip: isShow
                          ? L10n.of(context)!.shrink
                          : L10n.of(context)!.expand,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResponsiveButtons(BuildContext context) {
    if (!getIt.get<ResponsiveUtils>().isSingleColumnLayout(context)) return [];

    return [
      _NewGroupButton(
        onPressed: goToNewGroupChat,
      ),
    ];
  }
}

class _IconTextTileButton extends StatelessWidget {
  const _IconTextTileButton({
    required this.context,
    required this.onPressed,
    required this.iconData,
    required this.text,
  });

  final BuildContext context;
  final Function()? onPressed;
  final IconData iconData;
  final String text;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            height: 56.0,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(
                    iconData,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -0.15,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewGroupButton extends StatelessWidget {
  final Function() onPressed;

  const _NewGroupButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _IconTextTileButton(
      context: context,
      onPressed: onPressed,
      iconData: Icons.supervisor_account_outlined,
      text: L10n.of(context)!.newGroupChat,
    );
  }
}
