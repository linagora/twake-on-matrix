import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contacts_state.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/contacts_tab/empty_contacts_body.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/presentation_contact_success.dart';
import 'package:fluffychat/widgets/contacts_warning_banner/contacts_warning_banner_view.dart';
import 'package:fluffychat/widgets/sliver_expandable_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

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
        final success = phonebookContactState
            .getSuccessOrNull<PresentationContactsSuccess>();
        if (success == null || success.contacts.isEmpty) {
          return const SliverToBoxAdapter();
        }
        final contacts = success.contacts;
        return SliverExpandableList(
          title: L10n.of(context)!.contactsCount(contacts.length),
          itemCount: contacts.length,
          itemBuilder: (context, index) => _Contact(
            contact: contacts[index],
            controller: controller,
          ),
        );
      },
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
      builder: (context, state, child) => state.fold(
        (_) => child!,
        (success) {
          if (success is ContactsLoading) {
            return const SliverToBoxAdapter(
              child: LoadingContactWidget(),
            );
          }

          if (success is PresentationExternalContactSuccess) {
            return SliverToBoxAdapter(
              child: ExpansionContactListTile(
                contact: success.contact,
                highlightKeyword: controller.textEditingController.text,
              ),
            );
          }

          if (success is PresentationContactsSuccess) {
            final contacts = success.contacts;
            if (contacts.isEmpty) {
              if (controller.textEditingController.text.isEmpty) {
                return const SliverToBoxAdapter(child: EmptyContactBody());
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
      ),
      child: const SliverToBoxAdapter(
        child: SizedBox(),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
