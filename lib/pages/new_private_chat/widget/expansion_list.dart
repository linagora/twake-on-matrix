import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/presentation/enum/contacts/warning_contacts_banner_enum.dart';
import 'package:fluffychat/presentation/extensions/value_notifier_custom.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_empty.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_failure.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_success.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ExpansionList extends StatelessWidget {
  final ValueNotifierCustom<Either<Failure, Success>>
  presentationContactsNotifier;
  final ValueNotifierCustom<Either<Failure, Success>>
  presentationPhonebookContactNotifier;
  final Function() goToNewGroupChat;
  final Function(BuildContext context, PresentationContact contact)
  onExternalContactTap;
  final Function(BuildContext context, PresentationContact contact)
  onContactTap;
  final TextEditingController textEditingController;
  final ValueNotifier<WarningContactsBannerState> warningBannerNotifier;
  final Function()? closeContactsWarningBanner;
  final Function()? goToSettingsForPermissionActions;
  final VoidCallback? goToCreateContact;
  final bool phoneBookFilterSuccess;

  const ExpansionList({
    super.key,
    required this.presentationContactsNotifier,
    required this.goToNewGroupChat,
    required this.onExternalContactTap,
    required this.onContactTap,
    required this.textEditingController,
    required this.warningBannerNotifier,
    this.closeContactsWarningBanner,
    this.goToSettingsForPermissionActions,
    required this.presentationPhonebookContactNotifier,
    this.goToCreateContact,
    required this.phoneBookFilterSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._buildResponsiveButtons(context),
        _sliverContactsList(),
        if (PlatformInfos.isMobile) _sliverPhonebookList(),
      ],
    );
  }

  Widget _sliverContactsList() {
    return ValueListenableBuilder(
      valueListenable: presentationContactsNotifier,
      builder: (context, state, child) {
        return state.fold(
          (failure) {
            final textControllerIsEmpty = textEditingController.text.isEmpty;
            if (PlatformInfos.isWeb) {
              if (failure is GetPresentationContactsFailure ||
                  failure is GetPresentationContactsEmpty) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    NoContactsFound(
                      keyword: textControllerIsEmpty
                          ? null
                          : textEditingController.text,
                    ),
                  ],
                );
              }
              return child!;
            } else {
              return presentationPhonebookContactNotifier.value.fold((_) {
                if (presentationPhonebookContactNotifier.value.isRight()) {
                  return child!;
                }
                if (failure is GetPresentationContactsFailure ||
                    failure is GetPresentationContactsEmpty) {
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      NoContactsFound(
                        keyword: textControllerIsEmpty
                            ? null
                            : textEditingController.text,
                      ),
                    ],
                  );
                }
                return child!;
              }, (success) => child!);
            }
          },
          (success) {
            if (success is ContactsLoading) {
              return const LoadingContactWidget();
            }

            if (success is PresentationExternalContactSuccess) {
              if (!PlatformInfos.isWeb) {
                if (phoneBookFilterSuccess) {
                  return child!;
                }
              }
              return TwakeInkWell(
                onTap: () {
                  onContactTap(context, success.contact);
                },
                child: ExpansionContactListTile(
                  contact: success.contact,
                  highlightKeyword: textEditingController.text,
                ),
              );
            }

            if (success is PresentationContactsSuccess) {
              final contacts = success.contacts;
              if (contacts.isEmpty && textEditingController.text.isNotEmpty) {
                return NoContactsFound(
                  keyword: textEditingController.text.isEmpty
                      ? null
                      : textEditingController.text,
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  if (contacts[index].matrixId != null &&
                      contacts[index].matrixId!.isNotEmpty) {
                    return TwakeInkWell(
                      onTap: () {
                        onContactTap(context, contacts[index]);
                      },
                      child: ExpansionContactListTile(
                        contact: contacts[index],
                        highlightKeyword: textEditingController.text,
                      ),
                    );
                  }
                  return child!;
                },
              );
            }

            return child!;
          },
        );
      },
      child: const SizedBox(),
    );
  }

  Widget _sliverPhonebookList() {
    return ValueListenableBuilder(
      valueListenable: presentationPhonebookContactNotifier,
      builder: (context, phonebookContactState, child) {
        return phonebookContactState.fold(
          (failure) {
            return child!;
          },
          (success) {
            if (success is PresentationContactsSuccess) {
              final contacts = success.contacts;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  if (contacts[index].matrixId != null &&
                      contacts[index].matrixId!.isNotEmpty) {
                    return TwakeInkWell(
                      onTap: () {
                        onContactTap(context, contacts[index]);
                      },
                      child: ExpansionContactListTile(
                        contact: contacts[index],
                        highlightKeyword: textEditingController.text,
                      ),
                    );
                  }
                  return child!;
                },
              );
            }
            return child!;
          },
        );
      },
      child: const SizedBox(),
    );
  }

  List<Widget> _buildResponsiveButtons(BuildContext context) {
    if (!getIt.get<ResponsiveUtils>().isSingleColumnLayout(context)) return [];

    return [
      _NewGroupButton(onPressed: goToNewGroupChat),
      if (PlatformInfos.isMobile)
        _CreateContactButton(onPressed: goToCreateContact),
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

  const _NewGroupButton({required this.onPressed});

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

class _CreateContactButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _CreateContactButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _IconTextTileButton(
      context: context,
      onPressed: onPressed,
      iconData: Icons.person_add_outlined,
      text: L10n.of(context)!.createNewContact,
    );
  }
}
