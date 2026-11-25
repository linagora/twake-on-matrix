import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab_body_view.dart';
import 'package:twake_chat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

class _MockClient extends Mock implements Client {}

class _TestContactsTabController extends Mock
    with ContactsViewControllerMixin
    implements ContactsTabController {
  @override
  bool get enableRecentContacts => false;

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
    controller = _TestContactsTabController();
  });

  tearDown(() async {
    controller.disposeContactsMixin();
    await getIt.reset();
  });

  testWidgets('the client dropped while mounted: nothing is shown', (
    tester,
  ) async {
    Client? active = _MockClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activeMatrixClientProvider.overrideWith((ref) => active)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(body: ContactsTabBodyView(controller)),
        ),
      ),
    );
    expect(find.byType(CustomScrollView), findsOneWidget);

    active = null;
    ProviderScope.containerOf(
      tester.element(find.byType(ContactsTabBodyView)),
    ).invalidate(activeMatrixClientProvider);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomScrollView), findsNothing);
  });
}
