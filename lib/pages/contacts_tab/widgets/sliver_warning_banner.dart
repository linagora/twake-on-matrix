import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/widgets/contacts_warning_banner/contacts_warning_banner_view.dart';
import 'package:flutter/material.dart';

class SliverWarningBanner extends StatelessWidget {
  const SliverWarningBanner({required this.controller, super.key});

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
