import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/space_row_actions.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';

import '../../../utils/pump_localized.dart';

void main() {
  group('SpaceRowActions', () {
    testWidgets('foldToggle_whenTapped_fires', (tester) async {
      var toggled = 0;
      await pumpLocalized(
        tester,
        ProviderContainer.test(),
        Scaffold(
          body: SpaceRowActions(
            name: 'Team',
            space: SpaceRowData(
              fold: SpaceFold.open,
              unreadCount: 0,
              mentionCount: 0,
              onToggleFold: () => toggled++,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Hide the rooms of Team'));

      expect(toggled, 1);
    });

    testWidgets('add_whenTapped_fires', (tester) async {
      var added = 0;
      await pumpLocalized(
        tester,
        ProviderContainer.test(),
        Scaffold(
          body: SpaceRowActions(
            name: 'Team',
            space: SpaceRowData(
              fold: SpaceFold.none,
              unreadCount: 0,
              mentionCount: 0,
              onToggleFold: () {},
              onAddSubspace: () => added++,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));

      expect(added, 1);
    });
  });
}
