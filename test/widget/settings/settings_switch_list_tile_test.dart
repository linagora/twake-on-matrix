import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';
import 'package:twake_chat/utils/famedlysdk_store.provider.dart';
import 'package:twake_chat/widgets/settings_switch_list_tile.dart';

/// A store whose writes complete only when the test says so.
class _GatedStore extends Store {
  final writeGate = Completer<void>();

  @override
  Future<void> setItemBool(String key, bool value) async {
    await writeGate.future;
    await super.setItemBool(key, value);
  }
}

void main() {
  const key = 'chat.test.setting';

  Future<List<bool>> pumpTile(WidgetTester tester, {Store? store}) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [storeProvider.overrideWithValue(store ?? Store())],
        child: MaterialApp(
          home: Scaffold(
            body: SettingsSwitchListTile.adaptive(
              title: 'Test setting',
              storeKey: key,
              defaultValue: false,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return changes;
  }

  bool switchValue(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value;

  testWidgets('shows the value stored for its key', (tester) async {
    SharedPreferences.setMockInitialValues({key: true});

    await pumpTile(tester);

    expect(switchValue(tester), isTrue);
  });

  testWidgets('stores the new value and notifies onChanged', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final changes = await pumpTile(tester);
    expect(switchValue(tester), isFalse);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(switchValue(tester), isTrue);
    expect(changes, [true]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(key), isTrue);
  });

  testWidgets('does not touch its state when removed during the write', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = _GatedStore();
    await pumpTile(tester, store: store);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    store.writeGate.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
