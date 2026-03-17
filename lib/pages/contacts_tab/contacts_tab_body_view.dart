import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_contacts_with_matrix_id.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_contacts_without_matrix_id.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_empty_contacts.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_invite_friend_button.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_loading_contacts.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_phonebook_contacts_with_matrix_id.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_phonebook_contacts_without_matrix_id.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_recent_contacts.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_warning_banner.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

class ContactsTabBodyView extends StatelessWidget {
  final ContactsTabController controller;

  const ContactsTabBodyView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (controller.client.userID != null)
          SliverInviteFriendButton(userId: controller.client.userID!),
        SliverWarningBanner(controller: controller),
        SliverRecentContacts(controller: controller),
        SliverLoadingContacts(controller: controller),
        SliverContactsWithMatrixId(controller: controller),
        if (PlatformInfos.isMobile)
          SliverPhonebookContactsWithMatrixId(controller: controller),
        SliverContactsWithoutMatrixId(controller: controller),
        if (PlatformInfos.isMobile)
          SliverPhonebookContactsWithoutMatrixId(controller: controller),
        SliverEmptyContacts(controller: controller),
        const SliverToBoxAdapter(
          child: SizedBox(height: ContactsTabViewStyle.padding),
        ),
      ],
    );
  }
}
