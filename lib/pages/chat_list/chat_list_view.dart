import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_widget_extension.dart';
import 'package:flutter/material.dart';

class ChatListView extends StatelessWidget {
  final ChatListController controller;

  const ChatListView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: controller.buildAppBar(),
      body: controller.buildBody(),
      bottomNavigationBar: NavigationBar(
        height: 80,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        selectedIndex: controller.selectedIndex,
        onDestinationSelected:
            controller.onDestinationSelected,
        destinations: controller.getNavigationDestinations(context),
      ),
      floatingActionButtonLocation:FloatingActionButtonLocation.endFloat,
      floatingActionButton: controller.buildFloatingButton(),
    );
  }
}
