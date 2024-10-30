import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/settings_dashboard/settings_multiple_emotes/settings_multiple_emotes.dart';
import 'package:fluffychat/widgets/matrix.dart';

class MultipleEmotesSettingsView extends StatelessWidget {
  final MultipleEmotesSettingsController controller;

  const MultipleEmotesSettingsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final room = Matrix.of(context).client.getRoomById(controller.roomId!)!;
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.emotePacks,
        context: context,
      ),
      body: StreamBuilder(
        stream: room.onUpdate.stream,
        builder: (context, snapshot) {
          final Map<String, Event?> packs =
              room.states['im.ponies.room_emotes'] ?? <String, Event>{};
          if (!packs.containsKey('')) {
            packs[''] = null;
          }
          final keys = packs.keys.toList();
          keys.sort();
          return ListView.separated(
            separatorBuilder: (BuildContext context, int i) => Container(),
            itemCount: keys.length,
            itemBuilder: (BuildContext context, int i) {
              final event = packs[keys[i]];
              String? packName = keys[i].isNotEmpty ? keys[i] : 'Default Pack';
              if (event != null && event.content['pack'] is Map) {
                final packContent = event.content['pack'];
                if (packContent != null && packContent is Map<String, String>) {
                  if (packContent['displayname'] is String) {
                    packName = packContent['displayname'];
                  } else if (packContent['name'] is String) {
                    packName = packContent['name'];
                  }
                }
              }
              return ListTile(
                title: Text(packName!),
                onTap: () async {
                  context.go('rooms/${room.id}/details/emotes/${keys[i]}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
