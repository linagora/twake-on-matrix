import 'package:async/async.dart';
import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_view.dart';
import 'package:fluffychat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

class AdaptiveScaffoldApp extends StatefulWidget {
  final String? activeChat;

  const AdaptiveScaffoldApp({
    super.key,
    this.activeChat,
  });

  @override
  State<AdaptiveScaffoldApp> createState() => AdaptiveScaffoldAppController();
}

class AdaptiveScaffoldAppController extends State<AdaptiveScaffoldApp> {
  late final profileMemoizers = <Client?, AsyncMemoizer<Profile>>{};

  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBar =
      ValueNotifier<AdaptiveDestinationEnum>(AdaptiveDestinationEnum.rooms);

  Future<Profile?> fetchOwnProfile() {
    if (!profileMemoizers.containsKey(matrix.client)) {
      profileMemoizers[matrix.client] = AsyncMemoizer();
    }
    return profileMemoizers[matrix.client]!.runOnce(() async {
      return await matrix.client.fetchOwnProfile();
    });
  }

  void onDestinationSelected(int index) {
    switch (index) {
      //FIXME: NOW WE SUPPORT FOR ONLY 2 TABS
      case 0:
        activeNavigationBar.value = AdaptiveDestinationEnum.contacts;
        break;
      case 1:
        activeNavigationBar.value = AdaptiveDestinationEnum.rooms;
        break;
      default:
        break;
    }
  }

  int get activeNavigationBarIndex {
    switch (activeNavigationBar.value) {
      case AdaptiveDestinationEnum.contacts:
        return 0;
      case AdaptiveDestinationEnum.rooms:
        return 1;
      default:
        return 1;
    }
  }

  void clientSelected(
    Object object,
    BuildContext context,
  ) async {
    if (object is SettingsAction) {
      switch (object) {
        case SettingsAction.settings:
          context.go('/rooms/settings');
          break;
        case SettingsAction.archive:
          context.go('/rooms/archive');
          break;
        case SettingsAction.addAccount:
        case SettingsAction.newStory:
        case SettingsAction.newSpace:
        case SettingsAction.invite:
          break;

        default:
          break;
      }
    }
  }

  MatrixState get matrix => Matrix.of(context);

  @override
  Widget build(BuildContext context) => AppScaffoldView(
        controller: this,
        activeChat: widget.activeChat,
      );
}
