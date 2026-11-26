import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/add_to_space_row.dart';

import '../../../utils/pump_localized.dart';

void main() {
  final label = lookupL10n(const Locale('en')).spaceAddRoom;

  Future<void> pumpRow(WidgetTester tester, {VoidCallback? onTap}) =>
      pumpLocalized(
        tester,
        ProviderContainer.test(retry: (_, _) => null),
        Scaffold(body: AddToSpaceRow(depth: 1, onTap: onTap ?? () {})),
      );

  group('AddToSpaceRow', () {
    testWidgets('names what it adds, in the primary colour', (tester) async {
      await pumpRow(tester);

      final text = tester.widget<Text>(find.text(label));
      final style = DefaultTextStyle.of(
        tester.element(find.text(label)),
      ).style.merge(text.style);
      expect(style.color, LinagoraSysColors.material().primary);
    });

    testWidgets('shows a « + » where the avatars are', (tester) async {
      await pumpRow(tester);

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(
        tester.getCenter(find.byIcon(Icons.add)).dx,
        lessThan(tester.getTopLeft(find.text(label)).dx),
      );
    });

    testWidgets('a tap on the line calls the add action', (tester) async {
      var added = 0;
      await pumpRow(tester, onTap: () => added++);

      await tester.tap(find.text(label));

      expect(added, 1);
    });
  });
}
