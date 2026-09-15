import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:twake_chat/pages/contacts_tab/widgets/sliver_contacts_with_matrix_id.dart';
import 'package:twake_chat/pages/contacts_tab/widgets/sliver_contacts_without_matrix_id.dart';
import 'package:twake_chat/pages/contacts_tab/widgets/sliver_empty_contacts.dart';
import 'package:twake_chat/pages/contacts_tab/widgets/sliver_invite_friend_button.dart';
import 'package:twake_chat/pages/contacts_tab/widgets/sliver_loading_contacts.dart';
import 'package:twake_chat/pages/contacts_tab/widgets/sliver_phonebook_contacts_with_matrix_id.dart';
import 'package:twake_chat/pages/contacts_tab/widgets/sliver_phonebook_contacts_without_matrix_id.dart';
import 'package:twake_chat/pages/contacts_tab/widgets/sliver_warning_banner.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactsTabBodyView extends ConsumerWidget {
  final ContactsTabController controller;

  const ContactsTabBodyView(this.controller, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInvitationEnabled = ref.watch(
      loginHomeserverSummaryProvider.select(
        (summary) => summary.isInvitationEnabled,
      ),
    );
    return RefreshIndicator(
      onRefresh: controller.retrySynchronizeContacts,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (isInvitationEnabled && controller.client.userID != null)
            SliverInviteFriendButton(userId: controller.client.userID!),
          SliverWarningBanner(controller: controller),
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
      ),
    );
  }
}
