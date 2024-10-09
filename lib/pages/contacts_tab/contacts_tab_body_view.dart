import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contacts_state.dart';
import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/contacts_tab/empty_contacts_body.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
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
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

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
        _SliverWarningBanner(controller: controller),
        _SliverPhonebookLoading(controller: controller),
        _SliverRecentContacts(controller: controller),
        _SliverContactsList(controller: controller),
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
                      final keyword = controller.textEditingController.text;
                      if (keyword.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: EmptyContactBody(),
                        );
                      } else if (keyword.isValidMatrixId &&
                          keyword.startsWith("@")) {
                        final externalContact = PresentationContact(
                          matrixId: keyword,
                          displayName: keyword.substring(1),
                          type: ContactType.external,
                        );
                        return _SilverExternalContact(
                          controller: controller,
                          externalContact: externalContact,
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
            if (success is ContactsLoading) {
              return const SliverToBoxAdapter(
                child: LoadingContactWidget(),
              );
            }

            if (success is PresentationExternalContactSuccess) {
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
        child: TwakeInkWell(
          onTap: () {
            controller.onContactTap(
              context: context,
              path: 'rooms',
              contact: externalContact,
            );
          },
          child: ExpansionContactListTile(
            contact: externalContact,
            highlightKeyword: controller.textEditingController.text,
          ),
        ),
      ),
    );
  }
}

class _SliverPhonebookLoading extends StatelessWidget {
  const _SliverPhonebookLoading({
    required this.controller,
  });

  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.presentationPhonebookContactNotifier,
      builder: (context, phonebookContactState, child) {
        final loading = phonebookContactState
            .getSuccessOrNull<GetPhonebookContactsLoading>();
        if (loading == null) {
          return const SliverToBoxAdapter();
        }
        return SliverToBoxAdapter(
          child: _PhonebookLoading(progress: loading.progress),
        );
      },
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

class _PhonebookLoading extends StatelessWidget {
  final int progress;

  const _PhonebookLoading({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ContactsTabViewStyle.loadingPadding,
      child: Column(
        children: [
          Text(
            L10n.of(context)!.fetchingPhonebookContacts(progress),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: LinagoraRefColors.material().tertiary[20]),
          ),
          const SizedBox(height: ContactsTabViewStyle.loadingSpacer),
          LinearProgressIndicator(
            value: progress / 100,
          ),
        ],
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
      child: TwakeInkWell(
        onTap: () {
          controller.onContactTap(
            context: context,
            path: 'rooms',
            contact: contact,
          );
        },
        child: ExpansionContactListTile(
          contact: contact,
          highlightKeyword: controller.textEditingController.text,
        ),
      ),
    );
  }
}
