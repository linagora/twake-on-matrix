import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_list.dart';
import 'package:fluffychat/utils/platform_infos.dart';
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
          toggleSearchMode: controller.toggleSearchMode,
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
          contactsNotifier: controller.contactsNotifier,
          goToNewGroupChat: controller.goToNewGroupChat,
          isSearchModeNotifier: controller.isSearchModeNotifier,
          isShowContactsNotifier: controller.isShowContactsNotifier,
          onContactTap: controller.onContactAction,
          onExternalContactTap: controller.onExternalContactAction,
          toggleContactsList: controller.toggleContactsList,
        ),
      ),
    );
  }
}
