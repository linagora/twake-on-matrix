import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/config/app_config.dart';
import 'homeserver_picker.dart';

class HomeserverAppBar extends StatelessWidget {
  final HomeserverPickerController controller;

  const HomeserverAppBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: controller.homeserverFocusNode,
      controller: controller.homeserverController,
      contextMenuBuilder: mobileTwakeContextMenuBuilder,
      onChanged: controller.onChanged,
      decoration: InputDecoration(
        prefixIcon: Navigator.of(context).canPop()
            ? IconButton(
                onPressed: Navigator.of(context).pop,
                icon: const Icon(
                  Icons.chevron_left_outlined,
                ),
              )
            : null,
        prefixText: '${L10n.of(context)!.homeserver}: ',
        hintText: L10n.of(context)!.enterYourHomeserver,
        suffixIcon: const Icon(Icons.search),
        errorText: controller.error,
      ),
      readOnly: !AppConfig.allowOtherHomeservers,
      onSubmitted: (_) => controller.checkHomeserverAction(),
      autocorrect: false,
    );
  }
}
