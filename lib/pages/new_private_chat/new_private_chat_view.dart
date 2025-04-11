import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat_style.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_list.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar_style.dart';
import 'package:fluffychat/widgets/contacts_warning_banner/contacts_warning_banner_view.dart';
import 'package:fluffychat/widgets/phone_book_loading/phone_book_loading_view.dart';
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
        padding: NewPrivateChatStyle.paddingBody,
        controller: controller.scrollController,
        child: Column(
          children: [
            Padding(
              padding: NewPrivateChatStyle.paddingWarningBanner,
              child: ContactsWarningBannerView(
                warningBannerNotifier: controller.warningBannerNotifier,
                closeContactsWarningBanner:
                    controller.closeContactsWarningBanner,
                goToSettingsForPermissionActions: () =>
                    controller.displayContactPermissionDialog(context),
                isShowMargin: false,
              ),
            ),
            _phonebookLoading(),
            ExpansionList(
              presentationContactsNotifier:
                  controller.presentationContactNotifier,
              presentationPhonebookContactNotifier:
                  controller.presentationPhonebookContactNotifier,
              presentationAddressBookNotifier:
                  controller.presentationAddressBookNotifier,
              goToNewGroupChat: () => controller.goToNewGroupChat(context),
              onContactTap: controller.onContactAction,
              onExternalContactTap: controller.onExternalContactAction,
              textEditingController: controller.textEditingController,
              warningBannerNotifier: controller.warningBannerNotifier,
              closeContactsWarningBanner: controller.closeContactsWarningBanner,
              goToSettingsForPermissionActions: () =>
                  controller.displayContactPermissionDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phonebookLoading() {
    return ValueListenableBuilder(
      valueListenable: controller.contactsManager.progressPhoneBookState,
      builder: (context, progressValue, _) {
        if (progressValue != null) {
          return PhoneBookLoadingView(progress: progressValue);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
