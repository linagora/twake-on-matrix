import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';

import 'package:fluffychat/pages/settings_dashboard/settings_stories/settings_stories.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SettingsStoriesView extends StatelessWidget {
  final SettingsStoriesController controller;
  const SettingsStoriesView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: AppBar(
        backgroundColor: LinagoraSysColors.material().onPrimary,
        title: Text(L10n.of(context)!.whoCanSeeMyStories),
        elevation: 0,
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(L10n.of(context)!.whoCanSeeMyStoriesDesc),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).secondaryHeaderColor,
              foregroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.lock),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder(
              future: controller.loadUsers,
              builder: (context, snapshot) {
                final error = snapshot.error;
                if (error != null) {
                  return Center(child: Text(error.toLocalizedString(context)));
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: controller.users.length,
                  itemBuilder: (context, i) {
                    final user = controller.users.keys.toList()[i];
                    return SwitchListTile.adaptive(
                      value: controller.users[user] ?? false,
                      onChanged: (_) => controller.toggleUser(user),
                      secondary: Avatar(
                        mxContent: user.avatarUrl,
                        name: user.calcDisplayname(),
                      ),
                      title: Text(user.calcDisplayname()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
