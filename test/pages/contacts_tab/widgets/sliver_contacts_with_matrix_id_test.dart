import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/pages/contacts_tab/widgets/sliver_contacts_with_matrix_id.dart';
import 'package:twake_chat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:twake_chat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:twake_chat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:twake_chat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact_success.dart';

class _TestContactsTabController extends Mock
    with ContactsViewControllerMixin
    implements ContactsTabController {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      runtimeType.toString();
}

class _FakeProfileDatasource implements MatrixProfileDatasource {
  _FakeProfileDatasource(this._answer);

  final Future<MatrixUserProfile?> Function() _answer;
  final List<({String matrixId, bool fresh})> requests = [];

  @override
  Future<MatrixUserProfile?> fetchProfile(
    String matrixId, {
    bool fresh = false,
  }) {
    requests.add((matrixId: matrixId, fresh: fresh));
    return _answer();
  }
}

void main() {
  const matrixId = '@typed:server';
  late _TestContactsTabController controller;

  setUp(() {
    getIt.registerSingleton<SearchRecentChatInteractor>(
      SearchRecentChatInteractor(),
    );
    controller = _TestContactsTabController();
    controller.presentationContactNotifier.value = const Right(
      PresentationExternalContactSuccess(
        contact: PresentationContact(matrixId: matrixId, displayName: 'typed'),
      ),
    );
  });

  tearDown(() async {
    controller.disposeContactsMixin();
    await getIt.reset();
  });

  Future<void> pumpTile(
    WidgetTester tester,
    _FakeProfileDatasource datasource,
  ) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        matrixProfileDatasourceProvider.overrideWithValue(datasource),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [SliverContactsWithMatrixId(controller: controller)],
          ),
        ),
      ),
    ),
  );

  testWidgets('shows a loader while the homeserver is asked', (tester) async {
    final pending = Completer<MatrixUserProfile?>();
    final datasource = _FakeProfileDatasource(() => pending.future);

    await pumpTile(tester, datasource);

    expect(find.byType(LoadingContactWidget), findsOneWidget);
    expect(find.byType(NoContactsFound), findsNothing);
    // The existence check must not be answered from the SDK cache.
    expect(datasource.requests, [(matrixId: matrixId, fresh: true)]);
  });

  testWidgets('an unknown user is reported as not found', (tester) async {
    await pumpTile(tester, _FakeProfileDatasource(() async => null));
    await tester.pump();

    expect(find.byType(NoContactsFound), findsOneWidget);
    expect(find.byType(ExpansionContactListTile), findsNothing);
  });
}
