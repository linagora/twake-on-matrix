import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/new_private_chat/widget/new_private_chat_expansion_list_mobile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/new_private_chat_expansion_list_web.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class NewPrivateChatView extends StatelessWidget {
  final NewPrivateChatController controller;

  const NewPrivateChatView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: SearchableAppBarStyle.preferredSize(),
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
        child: !getIt.get<ResponsiveUtils>().isSingleColumnLayout(context)
            ? NewPrivateChatExpansionListWeb(
                presentationContactsNotifier:
                    controller.presentationContactNotifier,
                isShowContactsNotifier: controller.isShowContactsNotifier,
                onContactTap: controller.onContactAction,
                onExternalContactTap: controller.onExternalContactAction,
                toggleContactsList: controller.toggleContactsList,
                textEditingController: controller.textEditingController,
                warningBannerNotifier: controller.warningBannerNotifier,
                closeContactsWarningBanner:
                    controller.closeContactsWarningBanner,
                goToSettingsForPermissionActions:
                    controller.goToSettingsForPermissionActions,
              )
            : NewPrivateChatExpansionListMobile(
                presentationContactsNotifier:
                    controller.presentationContactNotifier,
                isShowContactsNotifier: controller.isShowContactsNotifier,
                goToNewGroupChat: controller.goToNewGroupChat,
                goToNewEncryptedChat: () => controller
                    .goToNewPrivateChat(context, enableEncryption: true),
                enableEncryption: controller.widget.enableEncryption,
                onContactTap: controller.onContactAction,
                onExternalContactTap: controller.onExternalContactAction,
                toggleContactsList: controller.toggleContactsList,
                textEditingController: controller.textEditingController,
                warningBannerNotifier: controller.warningBannerNotifier,
                closeContactsWarningBanner:
                    controller.closeContactsWarningBanner,
                goToSettingsForPermissionActions:
                    controller.goToSettingsForPermissionActions,
              ),
      ),
    );
  }
}
