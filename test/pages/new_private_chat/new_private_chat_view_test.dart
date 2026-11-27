import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/config/themes.dart';
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

  testWidgets('builds only the contact tiles that fit on screen', (
    tester,
  ) async {
    const contactCount = 300;
    final controller = NewPrivateChatScreenState();
    controller.presentationContactNotifier.value = Right(
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
    );
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

    final builtTiles = find
        .byType(ExpansionContactListTile, skipOffstage: false)
        .evaluate()
        .length;
    expect(builtTiles, greaterThan(0));
    expect(builtTiles, lessThan(contactCount ~/ 10));
  });
}
