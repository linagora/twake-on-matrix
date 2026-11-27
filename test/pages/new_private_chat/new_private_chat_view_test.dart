import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/contact/get_contacts_state.dart';
import 'package:twake_chat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:twake_chat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:twake_chat/presentation/model/contact/get_presentation_contacts_empty.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact_success.dart';
import 'package:twake_chat/domain/usecase/contacts/delete_third_party_contact_box_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/get_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/hive_delete_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/hive_get_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/new_private_chat/new_private_chat.dart';
import 'package:twake_chat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:twake_chat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:twake_chat/presentation/model/contact/get_presentation_contacts_success.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

class _FakeClient extends Fake implements Client {
  @override
  String? get userID => '@me:server';
}

class _FakeMatrixState extends Fake implements MatrixState {
  @override
  Client get client => _FakeClient();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

class _FakeHiveGetInvitationStatusInteractor extends Fake
    implements HiveGetInvitationStatusInteractor {}

class _FakeGetInvitationStatusInteractor extends Fake
    implements GetInvitationStatusInteractor {}

class _FakePostAddressBookInteractor extends Fake
    implements PostAddressBookInteractor {}

class _FakeHiveDeleteInvitationStatusInteractor extends Fake
    implements HiveDeleteInvitationStatusInteractor {}

class _FakeDeleteThirdPartyContactBoxInteractor extends Fake
    implements DeleteThirdPartyContactBoxInteractor {}

void main() {
  final getIt = GetIt.instance;

  setUp(() {
    getIt
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton(SearchRecentChatInteractor())
      ..registerSingleton<HiveGetInvitationStatusInteractor>(
        _FakeHiveGetInvitationStatusInteractor(),
      )
      ..registerSingleton<GetInvitationStatusInteractor>(
        _FakeGetInvitationStatusInteractor(),
      )
      ..registerSingleton<PostAddressBookInteractor>(
        _FakePostAddressBookInteractor(),
      )
      ..registerSingleton<HiveDeleteInvitationStatusInteractor>(
        _FakeHiveDeleteInvitationStatusInteractor(),
      )
      ..registerSingleton<DeleteThirdPartyContactBoxInteractor>(
        _FakeDeleteThirdPartyContactBoxInteractor(),
      );
  });

  tearDown(() => getIt.reset());

  Future<NewPrivateChatScreenState> pumpView(
    WidgetTester tester,
    Either<Failure, Success> contacts,
  ) async {
    final controller = NewPrivateChatScreenState();
    controller.presentationContactNotifier.value = contacts;
    addTearDown(controller.disposeContactsMixin);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: TwakeThemes.buildTheme(context, Brightness.light),
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: Provider<MatrixState>.value(
              value: _FakeMatrixState(),
              child: NewPrivateChatView(controller),
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('builds only the contact tiles that fit on screen', (
    tester,
  ) async {
    const contactCount = 300;
    await pumpView(
      tester,
      Right(
        GetPresentationContactsSuccess(
          keyword: '',
          contacts: List.generate(
            contactCount,
            (index) => PresentationContact(
              matrixId: '@user$index:server',
              displayName: 'Contact $index',
            ),
          ),
        ),
      ),
    );

    final builtTiles = find
        .byType(ExpansionContactListTile, skipOffstage: false)
        .evaluate()
        .length;
    expect(builtTiles, greaterThan(0));
    expect(builtTiles, lessThan(contactCount ~/ 10));
  });

  testWidgets('shows the loader while the contacts load', (tester) async {
    await pumpView(tester, const Right(ContactsLoading()));

    expect(find.byType(LoadingContactWidget), findsOneWidget);
    expect(find.byType(ExpansionContactListTile), findsNothing);
  });

  testWidgets('shows no results when no contact matches', (tester) async {
    await pumpView(
      tester,
      const Left(GetPresentationContactsEmpty(keyword: 'nobody')),
    );

    expect(find.byType(NoContactsFound), findsOneWidget);
    expect(find.byType(ExpansionContactListTile), findsNothing);
  });

  testWidgets('shows the typed Matrix ID as an external contact', (
    tester,
  ) async {
    const matrixId = '@typed:server';
    await pumpView(
      tester,
      const Right(
        PresentationExternalContactSuccess(
          contact: PresentationContact(
            matrixId: matrixId,
            displayName: 'typed',
          ),
        ),
      ),
    );

    expect(find.byType(ExpansionContactListTile), findsOneWidget);
    expect(
      tester
          .widget<ExpansionContactListTile>(
            find.byType(ExpansionContactListTile),
          )
          .contact
          .matrixId,
      matrixId,
    );
  });
}
