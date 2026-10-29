import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/homeserver_picker/homeserver_picker.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../providers/fake_login_sessions.dart';

void main() {
  final sessions = FakeLoginSessions();

  setUp(() => getIt.registerSingleton(ResponsiveUtils()));

  tearDown(() async {
    sessions.discards = 0;
    await GetIt.I.reset();
  });

  /// Leaves the picker by replacing the whole tree, and counts the candidates
  /// dropped on the way.
  Future<int> openAndLeave(
    WidgetTester tester,
    HomeserverPickerType type,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final picker = MaterialApp(
      home: HomeserverPicker(arg: HomeserverPickerArg(type: type)),
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: L10n.localizationsDelegates,
      theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [loginSessionsProvider.overrideWithValue(sessions)],
        child: picker,
      ),
    );
    await tester.pump();
    expect(sessions.discards, 0);

    await tester.pumpWidget(const SizedBox());
    return sessions.discards;
  }

  testWidgets(
    'the picker of the add-account flow drops the candidate on exit',
    (tester) async {
      expect(await openAndLeave(tester, HomeserverPickerType.multiAccount), 1);
    },
  );

  testWidgets('the picker of the first login has no candidate to drop', (
    tester,
  ) async {
    expect(await openAndLeave(tester, HomeserverPickerType.singleAccount), 0);
  });
}
