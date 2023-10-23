import 'dart:io';

import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/pages/chat_search/chat_search_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/pages/chat_search/chat_search.dart';

class ChatSearchView extends StatelessWidget {
  final ChatSearchController controller;

  const ChatSearchView(
    this.controller, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Platform.isAndroid) {
          controller.widget.onBack?.call();
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: ChatViewStyle.toolbarHeight(context),
          automaticallyImplyLeading: false,
          title: _ChatSearchAppBar(controller),
        ),
      ),
    );
  }
}

class _ChatSearchAppBar extends StatelessWidget {
  const _ChatSearchAppBar(
    this.controller,
  );

  final ChatSearchController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: ChatViewStyle.paddingLeading(context),
          child: TwakeIconButton(
            icon: Icons.arrow_back,
            onTap: controller.widget.onBack,
            tooltip: L10n.of(context)!.back,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ChatListHeaderStyle.searchRadiusBorder,
            ),
            child: Padding(
              padding: ChatSearchStyle.inputPadding,
              child: TextField(
                controller: controller.textEditingController,
                textInputAction: TextInputAction.search,
                autofocus: true,
                onChanged: (value) => controller.debouncer.setValue(value),
                decoration:
                    ChatListHeaderStyle.searchInputDecoration(context).copyWith(
                  suffixIcon: ValueListenableBuilder(
                    valueListenable: controller.textEditingController,
                    builder: (context, value, child) => value.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              controller.textEditingController.clear();
                            },
                            icon: const Icon(Icons.close),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
