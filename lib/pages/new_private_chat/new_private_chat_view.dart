import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_list.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class NewPrivateChatView extends StatelessWidget {
  final NewPrivateChatController controller;

  const NewPrivateChatView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: PreferredSize(
        preferredSize: SearchableAppBarStyle.preferredSize(context),
        child: SearchableAppBar(
          title: L10n.of(context)!.newChat,
          searchModeNotifier: controller.isSearchModeNotifier,
          textEditingController: controller.textEditingController,
          openSearchBar: controller.openSearchBar,
          closeSearchBar: controller.closeSearchBar,
          focusNode: controller.searchFocusNode,
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: PlatformInfos.isMobile
            ? ScrollViewKeyboardDismissBehavior.manual
            : ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(left: 8.0, right: 10.0),
        controller: controller.scrollController,
        child: ExpansionList(
          presentationContactsNotifier: controller.presentationContactNotifier,
          goToNewGroupChat: () => controller.goToNewGroupChat(context),
          isShowContactsNotifier: controller.isShowContactsNotifier,
          onContactTap: controller.onContactAction,
          onExternalContactTap: controller.onExternalContactAction,
          toggleContactsList: controller.toggleContactsList,
          textEditingController: controller.textEditingController,
          warningBannerNotifier: controller.warningBannerNotifier,
          closeContactsWarningBanner: controller.closeContactsWarningBanner,
          goToSettingsForPermissionActions:
              controller.goToSettingsForPermissionActions,
        ),
      ),
    );
  }
}
