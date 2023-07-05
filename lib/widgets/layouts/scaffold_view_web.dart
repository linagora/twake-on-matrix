import 'package:badges/badges.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';


class ScaffoldViewWeb extends StatefulWidget {

  final Widget child;

  const ScaffoldViewWeb({super.key, required this.child});

  @override
  State<ScaffoldViewWeb> createState() => _ScaffoldViewWebState();
}

class _ScaffoldViewWebState extends State<ScaffoldViewWeb> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        leadingWidth: 300,
        leading: Row(
          children: [
            const SizedBox(width: 16.0,),
            SvgPicture.asset(ImagePaths.icTwakeImageLogo, width: 44),
            const SizedBox(width: 16.0,),
            SvgPicture.asset(ImagePaths.icTwakeLogo, height: 30, fit: BoxFit.fitHeight,),
          ],
        ),
        actions: [
          TwakeIconButton(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            tooltip: 'Apps',
            imagePath: ImagePaths.icApplicationGrid,
          )
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            _buildSideBarWeb(),
            Expanded(
              child: Container(
                child: widget.child
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBarWeb() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: NavigationRail(
        labelType: NavigationRailLabelType.all,
        destinations: getNavigationRailDestinationsWeb(context),
        selectedIndex: selectedIndex,
        minExtendedWidth: 80,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onDestinationSelected: (selected) => onDestinationSelected(
          context: context,
          selected: selected,
        ),
        trailing: Expanded(
          child: Column(
            children: [
              const Expanded(child: SizedBox.shrink()),
              Container(height: 2, color: const Color(0xFFD7D8D9), width: 56,),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: FutureBuilder(
                  future: getCurrentUserProfile(context: context),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    return Avatar(
                      mxContent: profile?.avatarUrl,
                      name: profile?.displayName ?? profile?.userId,
                      size: 56,
                      onTap: () {},
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Profile> getCurrentUserProfile({required BuildContext context}) {
    return Matrix.of(context).client.getProfileFromUserId(Matrix.of(context).client.userID!);
  }

  void onDestinationSelected({
    required int selected, 
    required BuildContext context
  }) {
    setState(() {
      selectedIndex = selected;
      VRouter.of(context).to(BottomTabbarWeb.fromIndex(selected).path);
      if (selected == BottomTabbarWeb.stories.tabIndex) {
        Fluttertoast.showToast(
          msg: "Stories is not ready yet!",
          gravity: ToastGravity.BOTTOM,
        );
      }
    });
  }

  List<NavigationRailDestination> getNavigationRailDestinationsWeb(BuildContext context) {
    final badgePosition = BadgePosition.topEnd(top: -12, end: -8);
    return [
      if (AppConfig.separateChatTypes) ...[
        NavigationRailDestination(
          icon: const Icon(Icons.chat),
          label: Text(L10n.of(context)!.chat),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.web_stories_outlined),
          label: Text(L10n.of(context)!.stories),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.contacts_outlined),
          label: Text(L10n.of(context)!.contacts),
        ),
      ] else
        NavigationRailDestination(
          icon: const Icon(Icons.chat_outlined),
          label: Text(L10n.of(context)!.chats),
        ),
    ];
  }
}

enum BottomTabbarWeb {
  chats(tabIndex: 0, path: "/rooms"),
  stories(tabIndex: 1, path: "/stories"),
  contacts(tabIndex: 2, path: "/contactsTab");

  const BottomTabbarWeb({
    required this.tabIndex,
    required this.path,
  });

  factory BottomTabbarWeb.fromIndex(int? index) {
    switch (index) {
      case 0:
        return BottomTabbarWeb.chats;
      case 1:
        return BottomTabbarWeb.stories;
      case 2: 
        return BottomTabbarWeb.contacts;
      default: 
        return BottomTabbarWeb.chats;
    }
  }

  factory BottomTabbarWeb.fromPath(String path) {
    if (path == chats.path) {
      return chats;
    } else if (path == contacts.path) {
      return contacts;
    } else if (path == stories.path) {
      return stories;
    }
    return chats;
  }

  final int tabIndex;

  final String path;
}