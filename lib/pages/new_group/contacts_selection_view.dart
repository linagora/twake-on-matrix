import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/contacts_tab/empty_contacts_body.dart';
import 'package:fluffychat/pages/new_group/contacts_selection.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view_style.dart';
import 'package:fluffychat/pages/new_group/widget/contact_item.dart';
import 'package:fluffychat/pages/new_group/widget/contacts_selection_list_style.dart';
import 'package:fluffychat/pages/new_group/widget/selected_participants_list.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_empty.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_failure.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_success.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/contacts_warning_banner/contacts_warning_banner_view.dart';
import 'package:fluffychat/widgets/sliver_expandable_list.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ContactsSelectionView extends StatelessWidget {
  final ContactsSelectionController controller;
  final bool bannedHighlight;
  final Room? room;

  const ContactsSelectionView(
    this.controller, {
    super.key,
    this.bannedHighlight = false,
    this.room,
  });

  @override
  Widget build(BuildContext context) {
    final child = Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: PreferredSize(
        preferredSize: controller.isFullScreen
            ? ContactsSelectionViewStyle.preferredSize(context)
            : ContactsSelectionViewStyle.maxPreferredSize(context),
        child: SearchableAppBar(
          toolbarHeight: ContactsSelectionViewStyle.maxToolbarHeight(context),
          focusNode: controller.searchFocusNode,
          title: controller.getTitle(context),
          searchModeNotifier: controller.isSearchModeNotifier,
          hintText: controller.getHintText(context),
          textEditingController: controller.textEditingController,
          openSearchBar: controller.openSearchBar,
          closeSearchBar: controller.closeSearchBar,
          isFullScreen: controller.isFullScreen,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedContactsMapNotifier
                  .haveSelectedContactsNotifier,
              builder: (context, haveSelectedContact, child) {
                return child!;
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ContactsWarningBannerView(
                      warningBannerNotifier: controller.warningBannerNotifier,
                      closeContactsWarningBanner:
                          controller.closeContactsWarningBanner,
                      goToSettingsForPermissionActions: () =>
                          controller.displayContactPermissionDialog(context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SelectedParticipantsList(
                      contactsSelectionController: controller,
                    ),
                  ),
                  _sliverRecentContacts(),
                  _sliverContactsList(),
                  if (PlatformInfos.isMobile) _sliverPhonebookList(),
                ],
              ),
            ),
          ),
          if (!controller.isFullScreen) _webActionButton(context),
        ],
      ),
      floatingActionButton: controller.isFullScreen
          ? ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedContactsMapNotifier
                  .haveSelectedContactsNotifier,
              builder: (context, haveSelectedContacts, child) {
                if (!haveSelectedContacts) {
                  return const SizedBox.shrink();
                }
                return child!;
              },
              child: TwakeFloatingActionButton(
                icon: Icons.arrow_forward,
                onTap: () => controller.trySubmit(context),
              ),
            )
          : null,
    );

    return ScaffoldMessenger(child: child);
  }

  Widget _sliverRecentContacts() {
    return ValueListenableBuilder(
      valueListenable: controller.presentationContactNotifier,
      builder: (context, state, child) {
        return state.fold((failure) => child!, (success) {
          if (success is ContactsLoading) {
            return const SliverToBoxAdapter(child: SizedBox());
          }
          return child!;
        });
      },
      child: ValueListenableBuilder(
        valueListenable: controller.presentationRecentContactNotifier,
        builder: (context, recentContacts, child) {
          if (recentContacts.isEmpty) {
            return child!;
          }
          return SliverExpandableList(
            title: L10n.of(context)!.recent,
            itemCount: recentContacts.length,
            itemBuilder: (context, index) {
              final disabled = controller.disabledContactIds.contains(
                recentContacts[index].directChatMatrixID,
              );
              return ContactItem(
                disableBannedUser: bannedHighlight,
                room: room,
                contact: recentContacts[index].toPresentationContact(),
                selectedContactsMapNotifier:
                    controller.selectedContactsMapNotifier,
                onSelectedContact: controller.onSelectedContact,
                highlightKeyword: controller.textEditingController.text,
                disabled: disabled,
              );
            },
          );
        },
        child: const SliverToBoxAdapter(child: SizedBox()),
      ),
    );
  }

  Widget _sliverContactsList() {
    final recentContact =
        controller.presentationRecentContactNotifier.value.isEmpty;

    return ValueListenableBuilder(
      valueListenable: controller.presentationContactNotifier,
      builder: (context, state, child) {
        return state.fold(
          (failure) {
            if (PlatformInfos.isMobile) {
              return child!;
            }
            final presentationRecentContact =
                controller.presentationRecentContactNotifier.value;
            if (presentationRecentContact.isNotEmpty) {
              return child!;
            }
            if (PlatformInfos.isWeb) {
              if (failure is GetPresentationContactsFailure ||
                  failure is GetPresentationContactsEmpty) {
                final keyword = controller.textEditingController.text;
                if (keyword.isEmpty) {
                  return const SliverToBoxAdapter(child: EmptyContactBody());
                } else {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: ContactsSelectionListStyle.notFoundPadding,
                      child: NoContactsFound(
                        keyword: controller.textEditingController.text.isEmpty
                            ? null
                            : controller.textEditingController.text,
                      ),
                    ),
                  );
                }
              }
              return child!;
            } else {
              return controller.presentationPhonebookContactNotifier.value.fold(
                (_) {
                  if (controller.presentationPhonebookContactNotifier.value
                      .isRight()) {
                    return child!;
                  }
                  if (failure is GetPresentationContactsFailure ||
                      failure is GetPresentationContactsEmpty) {
                    final keyword = controller.textEditingController.text;
                    if (keyword.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: EmptyContactBody(),
                      );
                    } else {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: ContactsSelectionListStyle.notFoundPadding,
                          child: NoContactsFound(
                            keyword: controller.textEditingController.text,
                          ),
                        ),
                      );
                    }
                  }
                  return child!;
                },
                (success) => child!,
              );
            }
          },
          (success) {
            if (success is ContactsLoading) {
              return const SliverToBoxAdapter(child: LoadingContactWidget());
            }

            if (success is PresentationExternalContactSuccess &&
                recentContact) {
              if (controller
                  .presentationRecentContactNotifier
                  .value
                  .isNotEmpty) {
                return child!;
              }
              if (!PlatformInfos.isWeb) {
                if (controller.phoneBookFilterSuccess) {
                  return child!;
                }
              }
              return SliverToBoxAdapter(
                child: ContactItem(
                  disableBannedUser: bannedHighlight,
                  room: room,
                  contact: success.contact,
                  selectedContactsMapNotifier:
                      controller.selectedContactsMapNotifier,
                  onSelectedContact: controller.onSelectedContact,
                  highlightKeyword: controller.textEditingController.text,
                  disabled: false,
                ),
              );
            }

            if (success is PresentationContactsSuccess) {
              final contacts = success.contacts;
              if (contacts.isEmpty &&
                  controller.textEditingController.text.isNotEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: ContactsSelectionListStyle.notFoundPadding,
                    child: NoContactsFound(
                      keyword: controller.textEditingController.text,
                    ),
                  ),
                );
              }
              return SliverExpandableList(
                title: L10n.of(context)!.linagoraContactsCount(contacts.length),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final disabled = controller.disabledContactIds.contains(
                    contacts[index].matrixId,
                  );
                  return ContactItem(
                    disableBannedUser: bannedHighlight,
                    room: room,
                    contact: contacts[index],
                    selectedContactsMapNotifier:
                        controller.selectedContactsMapNotifier,
                    onSelectedContact: controller.onSelectedContact,
                    highlightKeyword: controller.textEditingController.text,
                    disabled: disabled,
                    paddingTop: index == 0
                        ? ContactsSelectionListStyle.listPaddingTop
                        : 0,
                  );
                },
              );
            }

            return child!;
          },
        );
      },
      child: const SliverToBoxAdapter(child: SizedBox()),
    );
  }

  Widget _sliverPhonebookList() {
    return ValueListenableBuilder(
      valueListenable: controller.presentationPhonebookContactNotifier,
      builder: (context, phonebookContactState, child) {
        return phonebookContactState.fold(
          (failure) {
            if (!PlatformInfos.isMobile) {
              return child!;
            }
            final presentationRecentContact =
                controller.presentationRecentContactNotifier.value;
            if (failure is GetPresentationContactsFailure) {
              if (presentationRecentContact.isEmpty) {
                return controller.presentationContactNotifier.value.fold((
                  failure,
                ) {
                  if (failure is GetPresentationContactsFailure ||
                      failure is GetPresentationContactsEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: ContactsSelectionListStyle.notFoundPadding,
                        child: NoContactsFound(
                          keyword: controller.textEditingController.text.isEmpty
                              ? null
                              : controller.textEditingController.text,
                        ),
                      ),
                    );
                  }
                  return child!;
                }, (_) => child!);
              }
            }
            if (failure is GetPresentationContactsEmpty) {
              if (presentationRecentContact.isEmpty) {
                return controller.presentationContactNotifier.value.fold((
                  failure,
                ) {
                  if (failure is GetPresentationContactsFailure ||
                      failure is GetPresentationContactsEmpty) {
                    if (controller.textEditingController.text.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: EmptyContactBody(),
                      );
                    } else {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: ContactsSelectionListStyle.notFoundPadding,
                          child: NoContactsFound(
                            keyword: controller.textEditingController.text,
                          ),
                        ),
                      );
                    }
                  }
                  return child!;
                }, (_) => child!);
              }
            }
            return child!;
          },
          (success) {
            if (success is PresentationContactsSuccess) {
              final contacts = success.contacts;
              return SliverExpandableList(
                title: L10n.of(context)!.linagoraContactsCount(contacts.length),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  if (contacts[index].matrixId != null &&
                      contacts[index].matrixId!.isNotEmpty) {
                    final disabled = controller.disabledContactIds.contains(
                      contacts[index].matrixId,
                    );
                    return ContactItem(
                      disableBannedUser: bannedHighlight,
                      room: room,
                      contact: contacts[index],
                      selectedContactsMapNotifier:
                          controller.selectedContactsMapNotifier,
                      onSelectedContact: controller.onSelectedContact,
                      highlightKeyword: controller.textEditingController.text,
                      disabled: disabled,
                      paddingTop: index == 0
                          ? ContactsSelectionListStyle.listPaddingTop
                          : 0,
                    );
                  }
                  return const SizedBox();
                },
              );
            }
            return child!;
          },
        );
      },
      child: const SliverToBoxAdapter(child: SizedBox()),
    );
  }

  Widget _webActionButton(BuildContext context) {
    return Padding(
      padding: ContactsSelectionViewStyle.webActionsButtonPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TwakeTextButton(
            onTap: () => Navigator.of(context).pop(),
            message: L10n.of(context)!.cancel,
            borderHover: ContactsSelectionViewStyle.webActionsButtonBorder,
            margin: ContactsSelectionViewStyle.webActionsButtonMargin,
            buttonDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ContactsSelectionViewStyle.webActionsButtonBorder,
              ),
            ),
            styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: LinagoraSysColors.material().primary,
            ),
          ),
          const SizedBox(width: 8.0),
          ValueListenableBuilder<bool>(
            valueListenable: controller
                .selectedContactsMapNotifier
                .haveSelectedContactsNotifier,
            builder: (context, haveSelectedContacts, _) {
              return TwakeTextButton(
                onTap: () =>
                    haveSelectedContacts ? controller.trySubmit(context) : null,
                message: L10n.of(context)!.add,
                margin: ContactsSelectionViewStyle.webActionsButtonMargin,
                borderHover: ContactsSelectionViewStyle.webActionsButtonBorder,
                buttonDecoration: BoxDecoration(
                  color: haveSelectedContacts
                      ? LinagoraSysColors.material().primary
                      : LinagoraStateLayer(
                          LinagoraSysColors.material().onSurface,
                        ).opacityLayer2,
                  borderRadius: BorderRadius.circular(
                    ContactsSelectionViewStyle.webActionsButtonBorder,
                  ),
                ),
                styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: haveSelectedContacts
                      ? LinagoraSysColors.material().onPrimary
                      : LinagoraSysColors.material().inverseSurface.withOpacity(
                          0.6,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
