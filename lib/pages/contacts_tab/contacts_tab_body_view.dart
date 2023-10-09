import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/contacts_tab/empty_contacts_body.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/model/presentation_contact_success.dart';
import 'package:fluffychat/widgets/twake_components/twake_smart_refresher.dart';
import 'package:flutter/material.dart';

class ContactsTabBodyView extends StatelessWidget {
  final ContactsTabController controller;

  const ContactsTabBodyView(
    this.controller, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.refreshController == null) return const SizedBox();
    return TwakeSmartRefresher(
      onRefresh: controller.fetchContacts,
      onLoading: controller.loadMoreContacts,
      controller: controller.refreshController!,
      slivers: [
        SliverToBoxAdapter(
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withOpacity(0.15),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(
            height: ContactsTabViewStyle.padding,
          ),
        ),
        if (controller.contactsNotifier != null)
          ValueListenableBuilder(
            valueListenable: controller.contactsNotifier!,
            builder: (context, value, child) => value.fold(
              (failure) => const SliverToBoxAdapter(child: EmptyContactBody()),
              (success) {
                if (success is! PresentationContactsSuccess) {
                  return const SliverToBoxAdapter(
                    child: LoadingContactWidget(),
                  );
                }

                if (success.data.isEmpty) {
                  if (success.keyword.isEmpty) {
                    return const SliverToBoxAdapter(child: EmptyContactBody());
                  } else {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: ContactsTabViewStyle.padding,
                          top: ContactsTabViewStyle.padding,
                        ),
                        child: NoContactsFound(
                          keyword: success.keyword,
                        ),
                      ),
                    );
                  }
                }

                return SliverList.builder(
                  itemCount: success.data.length,
                  itemBuilder: (context, index) {
                    final contact = success.data[index];
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
                          highlightKeyword: success.keyword,
                        ),
                      ),
                    );
                  },
                );
              },
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
