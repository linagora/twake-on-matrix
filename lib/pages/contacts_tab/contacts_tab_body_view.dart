import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/contacts_tab/empty_contacts_body.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_invite_friend_button.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_phonebook_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/pages/search/recent_item_widget.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_empty.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_failure.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_success.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/contacts_warning_banner/contacts_warning_banner_view.dart';
import 'package:fluffychat/widgets/sliver_expandable_list.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class ContactsTabBodyView extends StatelessWidget {
  final ContactsTabController controller;

  const ContactsTabBodyView(
    this.controller, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (controller.client.userID != null)
          SliverInviteFriendButton(userId: controller.client.userID!),
        _SliverWarningBanner(controller: controller),
        _SliverRecentContacts(controller: controller),
        _SliverContactsList(controller: controller),
        if (PlatformInfos.isMobile)
          _SliverPhonebookList(controller: controller),
        const _SliverPadding(),
      ],
    );
  }
}

class _SliverPadding extends StatelessWidget {
  const _SliverPadding();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: SizedBox(
        height: ContactsTabViewStyle.padding,
      ),
    );
  }
}

class _SliverPhonebookList extends StatelessWidget {
  const _SliverPhonebookList({
    required this.controller,
  });

  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
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
                return controller.presentationContactNotifier.value.fold(
                  (failure) {
                    if (failure is GetPresentationContactsFailure ||
                        failure is GetPresentationContactsEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: ContactsTabViewStyle.padding,
                            top: ContactsTabViewStyle.padding,
                          ),
                          child: NoContactsFound(
                            keyword:
                                controller.textEditingController.text.isEmpty
                                    ? null
                                    : controller.textEditingController.text,
                          ),
                        ),
                      );
                    }
                    return child!;
                  },
                  (_) => child!,
                );
              }
            }
            if (failure is GetPresentationContactsEmpty) {
              if (presentationRecentContact.isEmpty) {
                return controller.presentationContactNotifier.value.fold(
                  (failure) {
                    if (failure is GetPresentationContactsFailure ||
                        failure is GetPresentationContactsEmpty) {
                      if (controller.textEditingController.text.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: EmptyContactBody(),
                        );
                      } else {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: ContactsTabViewStyle.padding,
                              top: ContactsTabViewStyle.padding,
                            ),
                            child: NoContactsFound(
                              keyword: controller.textEditingController.text,
                            ),
                          ),
                        );
                      }
                    }
                    return child!;
                  },
                  (_) => child!,
                );
              }
            }
            return child!;
          },
          (success) {
            if (success is PresentationContactsSuccess) {
              final contacts = success.contacts;

              return SliverExpandableList(
                title: L10n.of(context)!.contactsCount(contacts.length),
                itemCount: contacts.length,
                itemBuilder: (context, index) => _PhonebookContact(
                  contact: contacts[index],
                  controller: controller,
                ),
              );
            }
            return child!;
          },
        );
      },
      child: const SliverToBoxAdapter(
        child: SizedBox(),
      ),
    );
  }
}

class _SliverContactsList extends StatelessWidget {
  const _SliverContactsList({
    required this.controller,
  });

  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
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
                  return const SliverToBoxAdapter(
                    child: EmptyContactBody(),
                  );
                } else {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: ContactsTabViewStyle.padding,
                        top: ContactsTabViewStyle.padding,
                      ),
                      child: NoContactsFound(
                        keyword: controller.textEditingController.text,
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
                          padding: const EdgeInsets.only(
                            left: ContactsTabViewStyle.padding,
                            top: ContactsTabViewStyle.padding,
                          ),
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
              return const SliverToBoxAdapter(
                child: LoadingContactWidget(),
              );
            }

            if (success is PresentationExternalContactSuccess) {
              if (controller
                  .presentationRecentContactNotifier.value.isNotEmpty) {
                return child!;
              }

              final externalContact = success.contact;
              return _SilverExternalContact(
                controller: controller,
                externalContact: externalContact,
              );
            }

            if (success is PresentationContactsSuccess) {
              final contacts = success.contacts;
              return SliverExpandableList(
                title: L10n.of(context)!.linagoraContactsCount(contacts.length),
                itemCount: contacts.length,
                itemBuilder: (context, index) => _Contact(
                  contact: contacts[index],
                  controller: controller,
                ),
              );
            }

            return child!;
          },
        );
      },
      child: const SliverToBoxAdapter(
        child: SizedBox(),
      ),
    );
  }
}

class _SilverExternalContact extends StatelessWidget {
  final ContactsTabController controller;
  final PresentationContact externalContact;

  const _SilverExternalContact({
    required this.controller,
    required this.externalContact,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ContactsTabViewStyle.padding,
        ),
        child: ExpansionContactListTile(
          contact: externalContact,
          highlightKeyword: controller.textEditingController.text,
          enableInvitation: controller.supportInvitation(),
          onContactTap: () => controller.onContactTap(
            context: context,
            path: 'rooms',
            contact: externalContact,
          ),
        ),
      ),
    );
  }
}

class _SliverRecentContacts extends StatelessWidget {
  final ContactsTabController controller;

  const _SliverRecentContacts({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.presentationContactNotifier,
      builder: (context, state, child) {
        return state.fold(
          (failure) => child!,
          (success) {
            if (success is ContactsLoading) {
              return const SliverToBoxAdapter(
                child: SizedBox(),
              );
            }
            return child!;
          },
        );
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
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ContactsTabViewStyle.padding,
              ),
              child: RecentItemWidget(
                presentationSearch: recentContacts[index],
                highlightKeyword: controller.textEditingController.text,
                client: controller.client,
                key: Key('contact_recent_${recentContacts[index].id}'),
                onTap: () => controller.onContactTap(
                  contact: recentContacts[index].toPresentationContact(),
                  context: context,
                  path: 'rooms',
                ),
                avatarSize: ContactsTabViewStyle.avatarSize,
              ),
            ),
          );
        },
        child: const SliverToBoxAdapter(
          child: SizedBox(),
        ),
      ),
    );
  }
}

class _SliverWarningBanner extends StatelessWidget {
  const _SliverWarningBanner({
    required this.controller,
  });

  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ContactsWarningBannerView(
        warningBannerNotifier: controller.warningBannerNotifier,
        closeContactsWarningBanner: controller.closeContactsWarningBanner,
        goToSettingsForPermissionActions: () =>
            controller.displayContactPermissionDialog(context),
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({
    required this.contact,
    required this.controller,
  });

  final PresentationContact contact;
  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ContactsTabViewStyle.padding,
      ),
      child: ExpansionContactListTile(
        contact: contact,
        highlightKeyword: controller.textEditingController.text,
        enableInvitation: controller.supportInvitation(),
        onContactTap: () => controller.onContactTap(
          context: context,
          path: 'rooms',
          contact: contact,
        ),
      ),
    );
  }
}

class _PhonebookContact extends StatelessWidget {
  const _PhonebookContact({
    required this.contact,
    required this.controller,
  });

  final PresentationContact contact;
  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ContactsTabViewStyle.padding,
      ),
      child: ExpansionPhonebookContactListTile(
        contact: contact,
        highlightKeyword: controller.textEditingController.text,
        enableInvitation: controller.supportInvitation(),
        onContactTap: () => controller.onContactTap(
          context: context,
          path: 'rooms',
          contact: contact,
        ),
      ),
    );
  }
}
