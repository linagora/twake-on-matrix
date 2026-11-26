import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab_view.dart';
import 'package:twake_chat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../../fake_client.dart';
import '../../providers/fake_active_account.dart';
import '../chat_list/chat_list_header_test_harness.dart' show FakeMatrixState;

/// `NavigationKeys.settingsAvatar`.
const _avatar = Key('navigation.settingsAvatar');

class _TestContactsTabController extends Mock
    with ContactsViewControllerMixin
    implements ContactsTabController {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      runtimeType.toString();
}

void main() {
  late _TestContactsTabController controller;

  setUp(() {
    getIt.registerSingleton<SearchRecentChatInteractor>(
      SearchRecentChatInteractor(),
    );
    getIt.registerSingleton(ResponsiveUtils());
    controller = _TestContactsTabController();
  });

  tearDown(() async {
    controller.disposeContactsMixin();
    await getIt.reset();
  });

  /// The Contacts tab with no contact; returns how many times it asked for
  /// Settings.
  Future<List<void>> pumpContacts(
    WidgetTester tester, {
    bool wide = false,
  }) async {
    tester.view.physicalSize = wide
        ? const Size(1400, 900)
        : const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = Client(
      'testclient',
      database: EventIdListDatabase(const []),
    );
    final opened = <void>[];
    await tester.pumpWidget(
      provider.Provider<MatrixState>.value(
        value: FakeMatrixState(client),
        child: UncontrolledProviderScope(
          container: ProviderContainer.test(
            retry: (_, _) => null,
            overrides: activeAccountOverrides(client),
          ),
          child: MaterialApp(
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: ContactsTabView(
              contactsController: controller,
              onOpenSettings: () => opened.add(null),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  group('[Contacts] settings avatar', () {
    testWidgets('GIVEN a phone\n'
        'THEN the avatar of the user sits at the start of the app bar', (
      tester,
    ) async {
      await pumpContacts(tester);

      expect(
        find.descendant(of: find.byKey(_avatar), matching: find.byType(Avatar)),
        findsOneWidget,
      );
      final avatar = tester.getRect(find.byKey(_avatar));
      final title = tester.getRect(find.text('Contacts'));
      expect(avatar.right, lessThan(title.left));
      // On the row of the title.
      expect(avatar.top, lessThan(title.bottom));
      expect(avatar.bottom, greaterThan(title.top));
    });

    testWidgets('GIVEN a phone\n'
        'WHEN the avatar is tapped\n'
        'THEN Settings opens', (tester) async {
      final opened = await pumpContacts(tester);

      await tester.tap(find.byKey(_avatar));
      await tester.pump();

      expect(opened, hasLength(1));
    });

    testWidgets('GIVEN a wide screen\n'
        'THEN the app bar has no avatar', (tester) async {
      await pumpContacts(tester, wide: true);

      expect(find.text('Contacts'), findsOneWidget);
      expect(find.byKey(_avatar), findsNothing);
    });
  });
}
