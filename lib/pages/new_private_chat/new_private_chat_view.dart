import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_list.dart';
import 'package:fluffychat/pages/new_private_chat/widget/new_private_chat_appbar.dart';
import 'package:flutter/material.dart';

class NewPrivateChatView extends StatelessWidget {
  final NewPrivateChatController controller;

  const NewPrivateChatView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: NewPrivateChatAppBar(newPrivateChatController: controller),),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 8.0, right: 10.0),
        child: ExpansionList(
          newPrivateChatController: controller,
        ),
      )
    );
  }
}
