import 'package:badges/badges.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_list/bottom_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vrouter/vrouter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class HomeScreen extends StatefulWidget {
  final Widget? child;

  const HomeScreen({super.key, this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 1;

  void onDestinationSelected(int selected) {
    setState(() {
      selectedIndex = selected;
      VRouter.of(context).to(BottomTabbar.fromIndex(selected).path);
      if (selected == BottomTabbar.stories.tabIndex) {
        Fluttertoast.showToast(
          msg: "Stories is not ready yet!",
          gravity: ToastGravity.BOTTOM,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surface,
        height: 84,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(
                height: 4.0, color: Theme.of(context).colorScheme.surface),
            NavigationBar(
              height: 80,
              surfaceTintColor: Theme.of(context).colorScheme.surface,
              selectedIndex:
                  BottomTabbar.fromPath(context.vRouter.path).tabIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: getNavigationDestinations(context),
            ),
          ],
        ),
      ),
    );
  }

  List<NavigationDestination> getNavigationDestinations(BuildContext context) {
    // ignore: unused_local_variable
    final badgePosition = BadgePosition.topEnd(top: -12, end: -8);
    return [
      if (AppConfig.separateChatTypes) ...[
        NavigationDestination(
          icon: const Icon(Icons.contacts_outlined),
          label: L10n.of(context)!.contacts,
        ),
        NavigationDestination(
          icon: const Icon(Icons.chat),
          label: L10n.of(context)!.chat,
        ),
        NavigationDestination(
          icon: const Icon(Icons.web_stories_outlined),
          label: L10n.of(context)!.stories,
        ),
      ] else
        NavigationDestination(
          icon: const Icon(Icons.chat_outlined),
          label: L10n.of(context)!.chats,
        ),
    ];
  }
}
