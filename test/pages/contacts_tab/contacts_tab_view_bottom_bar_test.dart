import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:mockito/annotations.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/domain/usecase/contacts/delete_third_party_contact_box_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/get_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/hive_delete_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/hive_get_invitation_status_interactor.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab_view.dart';
import 'package:twake_chat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:twake_chat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact_success.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../../fake_client.dart';
import '../../providers/fake_active_account.dart';
import '../chat_list/chat_list_header_test_harness.dart' show FakeMatrixState;
import 'contacts_tab_view_bottom_bar_test.mocks.dart';

class _TestContactsTabController extends Mock
    with ContactsViewControllerMixin
    implements ContactsTabController {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      runtimeType.toString();
}

const _barKey = Key('bottom_bar');

@GenerateNiceMocks([
  MockSpec<HiveGetInvitationStatusInteractor>(),
  MockSpec<GetInvitationStatusInteractor>(),
  MockSpec<PostAddressBookInteractor>(),
  MockSpec<HiveDeleteInvitationStatusInteractor>(),
  MockSpec<DeleteThirdPartyContactBoxInteractor>(),
])
void main() {
  late _TestContactsTabController controller;

  setUp(() {
    getIt.registerSingleton<SearchRecentChatInteractor>(
      SearchRecentChatInteractor(),
    );
    getIt.registerSingleton(ResponsiveUtils());
    // ExpansionContactListTile resolves these when it is built.
    getIt
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
    controller = _TestContactsTabController();
    controller.presentationContactNotifier.value = Right(
      PresentationContactsSuccess(
        keyword: '',
        contacts: [
          for (var i = 0; i < 30; i++)
            PresentationContact(
              matrixId: '@user$i:server',
              displayName: 'User $i',
            ),
        ],
      ),
    );
  });

  tearDown(() async {
    controller.disposeContactsMixin();
    await getIt.reset();
  });

  testWidgets('whenScrolledToTheEnd_lastContactEndsAboveTheBottomBar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = Client(
      'testclient',
      database: EventIdListDatabase(const []),
    );
    await tester.pumpWidget(
      provider.Provider<MatrixState>.value(
        value: FakeMatrixState(client),
        child: UncontrolledProviderScope(
          container: ProviderContainer.test(
            retry: (_, _) => null,
            overrides: activeAccountOverrides(null),
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
              bottomNavigationBar: const SizedBox(key: _barKey, height: 80),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('User 29'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    final lastContact = tester.getRect(
      find.byType(ExpansionContactListTile).last,
    );
    expect(
      lastContact.bottom,
      lessThanOrEqualTo(tester.getRect(find.byKey(_barKey)).top),
    );
  });
}
