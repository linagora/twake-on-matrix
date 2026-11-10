import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/room/invite_user_state.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/usecase/room/unban_and_invite_users_interactor.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/invitation_selection/invitation_selection.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

import 'invitation_selection_test.mocks.dart';

class _FakeMatrix extends Fake implements MatrixState {
  _FakeMatrix(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

class _SlowInviteInteractor extends Fake
    implements UnbanAndInviteUsersInteractor {
  final result = StreamController<Either<Failure, Success>>();
  List<String>? invitedUserIds;

  @override
  Stream<Either<Failure, Success>> execute({
    required Room room,
    required List<String> userIds,
  }) {
    invitedUserIds = userIds;
    result.add(Right(InviteUserLoading()));
    return result.stream;
  }
}

const _roomId = '!group:hs1.localhost';
const _remoteUser = '@bob:hs2.localhost';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<SearchRecentChatInteractor>()])
void main() {
  late _SlowInviteInteractor interactor;

  setUp(() {
    interactor = _SlowInviteInteractor();
    GetIt.instance
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton<SearchRecentChatInteractor>(
        MockSearchRecentChatInteractor(),
      )
      ..registerSingleton<UnbanAndInviteUsersInteractor>(interactor);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> openInvitationAndSubmit(WidgetTester tester) async {
    final client = MockClient();
    when(
      client.getRoomById(_roomId),
    ).thenReturn(Room(id: _roomId, client: client));
    await tester.pumpWidget(
      ProviderScope(
        child: Provider<MatrixState>.value(
          value: _FakeMatrix(client),
          child: MaterialApp(
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const InvitationSelection(roomId: _roomId),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final controller = tester.state<InvitationSelectionController>(
      find.byType(InvitationSelection),
    );
    controller.selectedContactsMapNotifier.onContactTileTap(
      tester.element(find.byType(InvitationSelection)),
      const PresentationContact(matrixId: _remoteUser),
    );
    controller.onSubmit();
    await tester.pumpAndSettle();
  }

  group('InvitationSelection with a slow federated invite', () {
    testWidgets('whilePending_closesTheScreenAndSendsTheInvite', (
      tester,
    ) async {
      await openInvitationAndSubmit(tester);

      expect(interactor.invitedUserIds, [_remoteUser]);
      expect(find.byType(InvitationSelection), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('whenItSucceeds_showsTheInvitedSnackBar', (tester) async {
      await openInvitationAndSubmit(tester);

      interactor.result.add(const Right(InviteUserSuccess(roomId: _roomId)));
      await tester.pumpAndSettle();

      expect(find.text('Contact has been invited to the chat'), findsOneWidget);
    });

    testWidgets('whenItFails_showsTheFailureDialog', (tester) async {
      await openInvitationAndSubmit(tester);

      interactor.result.add(
        Left(
          InviteUserSomeFailed(
            inviteUserPartialFailureException:
                InviteUserPartialFailureException(
                  failedUsers: const {
                    _remoteUser: GenericInviteException(userId: _remoteUser),
                  },
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining("couldn't be added to the chat"),
        findsOneWidget,
      );
    });

    testWidgets('whenItThrows_showsAnErrorSnackBar', (tester) async {
      await openInvitationAndSubmit(tester);

      interactor.result.addError(Exception('unban failed'));
      await tester.pumpAndSettle();

      expect(find.text('Oops, something went wrong…'), findsOneWidget);
    });
  });
}
