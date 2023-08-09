import 'package:async/async.dart';
import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_shell_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

class AdaptiveScaffoldShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AdaptiveScaffoldShell({super.key, required this.navigationShell});

  @override
  State<AdaptiveScaffoldShell> createState() =>
      AdaptiveScaffoldShellController();
}

class AdaptiveScaffoldShellController extends State<AdaptiveScaffoldShell> {
  late final profileMemoizers = <Client?, AsyncMemoizer<Profile>>{};

  Future<Profile?> fetchOwnProfile() {
    if (!profileMemoizers.containsKey(matrix.client)) {
      profileMemoizers[matrix.client] = AsyncMemoizer();
    }
    return profileMemoizers[matrix.client]!.runOnce(() async {
      return await matrix.client.fetchOwnProfile();
    });
  }

  void clientSelected(
    Object object,
    BuildContext context,
  ) async {
    if (object is SettingsAction) {
      switch (object) {
        case SettingsAction.settings:
          context.push('/settings');
          break;
        case SettingsAction.archive:
          context.push('/archive');
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
  Widget build(BuildContext context) => AppScaffoldShellView(
        navigationShell: widget.navigationShell,
        controller: this,
      );
}
