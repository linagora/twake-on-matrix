import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/new_group/new_group.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

import 'contacts_selection_view_test.mocks.dart';

class _FakeMatrix extends Fake implements MatrixState {
  _FakeMatrix(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<SearchRecentChatInteractor>()])
void main() {
  setUpAll(() {
    GetIt.instance
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton<SearchRecentChatInteractor>(
        MockSearchRecentChatInteractor(),
      );
  });

  tearDownAll(() => GetIt.instance.reset());

  Future<void> pumpNewGroup(
    WidgetTester tester, {
    required NewGroupKind kind,
    String? parentSpaceId,
  }) async {
    final matrix = _FakeMatrix(MockClient());
    await tester.pumpWidget(
      ProviderScope(
        child: Provider<MatrixState>.value(
          value: matrix,
          child: MaterialApp(
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: NewGroup(kind: kind, parentSpaceId: parentSpaceId),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final submit = find.byIcon(Icons.arrow_forward);

  group('ContactsSelectionView submit button without anybody selected', () {
    testWidgets('whenPlainGroup_isHidden', (tester) async {
      await pumpNewGroup(tester, kind: NewGroupKind.group);

      expect(submit, findsNothing);
    });

    testWidgets('whenFeed_isHidden', (tester) async {
      await pumpNewGroup(tester, kind: NewGroupKind.feed);

      expect(submit, findsNothing);
    });

    testWidgets('whenSpace_isShown', (tester) async {
      await pumpNewGroup(tester, kind: NewGroupKind.space);

      expect(submit, findsOneWidget);
    });

    testWidgets('whenGroupInASpace_isShown', (tester) async {
      await pumpNewGroup(
        tester,
        kind: NewGroupKind.group,
        parentSpaceId: '!space',
      );

      expect(submit, findsOneWidget);
    });
  });
}
