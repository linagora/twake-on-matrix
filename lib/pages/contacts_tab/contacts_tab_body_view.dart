import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/contacts_tab/empty_contacts_body.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/widgets/contacts_warning_banner/contacts_warning_banner_view.dart';
import 'package:flutter/material.dart';

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
        SliverToBoxAdapter(
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withOpacity(0.15),
          ),
        ),
        SliverToBoxAdapter(
          child: ContactsWarningBannerView(
            warningBannerNotifier: controller.warningBannerNotifier,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(
            height: ContactsTabViewStyle.padding,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.presentationContactNotifier,
          builder: (context, state, child) => state.fold(
            (_) => child!,
            (success) {
              if (success is ContactsLoading) {
                return const SliverToBoxAdapter(
                  child: LoadingContactWidget(),
                );
              }

              if (success is SearchExternalContactsSuccessState) {
                final externalContact = PresentationContact(
                  matrixId: success.keyword,
                  displayName: success.keyword.substring(1),
                  type: ContactType.external,
                );
                return SliverToBoxAdapter(
                  child: ExpansionContactListTile(
                    contact: externalContact,
                    highlightKeyword: controller.textEditingController.text,
                  ),
                );
              }

              if (success is GetContactsSuccess) {
                final contacts = success.tomContacts
                    .expand((contact) => contact.toPresentationContacts())
                    .toList();
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
                return SliverList.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
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
                          highlightKeyword:
                              controller.textEditingController.text,
                        ),
                      ),
                    );
                  },
                );
              }

              return child!;
            },
          ),
          child: const SliverToBoxAdapter(
            child: SizedBox(),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(
            height: ContactsTabViewStyle.padding,
          ),
        ),
      ],
    );
  }
}
