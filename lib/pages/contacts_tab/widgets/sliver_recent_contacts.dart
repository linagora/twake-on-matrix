import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/search/recent_item_widget.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/widgets/sliver_expandable_list.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class SliverRecentContacts extends StatelessWidget {
  const SliverRecentContacts({required this.controller, super.key});

  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.presentationContactNotifier,
      builder: (context, state, child) {
        return state.fold((_) => child!, (success) {
          if (success is ContactsLoading) {
            return const SliverToBoxAdapter();
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
        child: const SliverToBoxAdapter(),
      ),
    );
  }
}
