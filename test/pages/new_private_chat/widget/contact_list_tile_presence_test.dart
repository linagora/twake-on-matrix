import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, UncontrolledProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/model/contact/contact_status.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/domain/usecase/contacts/delete_third_party_contact_box_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/get_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/hive_delete_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/hive_get_invitation_status_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';
import 'package:twake_chat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:twake_chat/pages/new_private_chat/widget/expansion_phonebook_contact_list_tile.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/person_presence_badge.dart';
import 'package:twake_chat/widgets/matrix.dart';

import 'contact_list_tile_presence_test.mocks.dart';

const _alice = '@alice:server';

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<HiveGetInvitationStatusInteractor>(),
  MockSpec<GetInvitationStatusInteractor>(),
  MockSpec<PostAddressBookInteractor>(),
  MockSpec<HiveDeleteInvitationStatusInteractor>(),
  MockSpec<DeleteThirdPartyContactBoxInteractor>(),
])
void main() {
  setUp(() {
    getIt
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton<HiveGetInvitationStatusInteractor>(
        MockHiveGetInvitationStatusInteractor(),
      )
      ..registerSingleton<GetInvitationStatusInteractor>(
        MockGetInvitationStatusInteractor(),
      )
      ..registerSingleton<PostAddressBookInteractor>(
        MockPostAddressBookInteractor(),
      )
      ..registerSingleton<HiveDeleteInvitationStatusInteractor>(
        MockHiveDeleteInvitationStatusInteractor(),
      )
      ..registerSingleton<DeleteThirdPartyContactBoxInteractor>(
        MockDeleteThirdPartyContactBoxInteractor(),
      );
  });

  tearDown(() => getIt.reset());

  Future<void> pumpTile(
    WidgetTester tester,
    Widget Function(PresentationContact contact) tile,
    ContactStatus status, {
    bool profilePending = false,
  }) async {
    final client = MockClient();
    when(client.userID).thenReturn('@me:server');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [
            contactDisplayProvider(_alice).overrideWith(
              (ref) => profilePending
                  ? Completer<UnifiedContact>().future
                  : Future.value(const UnifiedContact(matrixId: _alice)),
            ),
            contactAvatarProvider(_alice).overrideWithValue(null),
            syncedPersonPresenceProvider(_alice).overrideWith(
              (ref) => Stream.value(
                const PersonPresence(status: PresenceStatus.online),
              ),
            ),
          ],
        ),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            theme: TwakeThemes.buildTheme(context, Brightness.light),
            home: Provider<MatrixState>.value(
              value: _FakeMatrixState(client),
              child: Scaffold(
                body: tile(
                  PresentationContact(
                    matrixId: _alice,
                    displayName: 'Alice',
                    status: status,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  for (final (name, tile) in <(String, Widget Function(PresentationContact))>[
    (
      'ExpansionContactListTile',
      (contact) => ExpansionContactListTile(contact: contact),
    ),
    (
      'ExpansionPhonebookContactListTile',
      (contact) => ExpansionPhonebookContactListTile(contact: contact),
    ),
  ]) {
    group(name, () {
      testWidgets('shows the presence of a contact on Twake', (tester) async {
        await pumpTile(tester, tile, ContactStatus.active);

        final badge = tester.widget<PersonPresenceBadge>(
          find.byType(PersonPresenceBadge),
        );
        expect(badge.userId, _alice);
        expect(find.byKey(const ValueKey('linagora-presence-dot')), findsOne);
      });

      testWidgets('shows the presence while the contact profile loads', (
        tester,
      ) async {
        await pumpTile(
          tester,
          tile,
          ContactStatus.active,
          profilePending: true,
        );

        expect(find.byKey(const ValueKey('linagora-presence-dot')), findsOne);
      });

      testWidgets('shows no presence for a contact not on Twake', (
        tester,
      ) async {
        await pumpTile(tester, tile, ContactStatus.inactive);

        expect(find.byType(PersonPresenceBadge), findsNothing);
      });
    });
  }
}
