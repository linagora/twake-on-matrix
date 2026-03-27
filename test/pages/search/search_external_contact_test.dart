import 'dart:async';

import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/domain/usecase/contacts/delete_third_party_contact_box_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/get_invitation_status_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/hive_delete_invitation_status_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/hive_get_invitation_status_interactor.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/search/search_external_contact.dart';
import 'package:fluffychat/utils/custom_scroll_behaviour.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import 'package:fluffychat/widgets/twake_components/twake_loading/center_loading_indicator.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'search_external_contact_test.mocks.dart';

/// Lightweight stand-in for [MatrixState] that only exposes [client].
/// We avoid mocking [MatrixState] directly because it references dart:html
/// types that are unavailable in VM tests.
class FakeMatrixState extends Fake implements MatrixState {
  FakeMatrixState(this._client);
  final Client _client;

  @override
  Client get client => _client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeMatrixState';
}

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<SearchController>(),
  MockSpec<TextEditingController>(),
  MockSpec<HiveGetInvitationStatusInteractor>(),
  MockSpec<GetInvitationStatusInteractor>(),
  MockSpec<PostAddressBookInteractor>(),
  MockSpec<HiveDeleteInvitationStatusInteractor>(),
  MockSpec<DeleteThirdPartyContactBoxInteractor>(),
])
void main() {
  late MockClient mockClient;
  late MockSearchController mockSearchController;
  late MockTextEditingController mockTextEditingController;

  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton(ResponsiveUtils());
  });

  setUp(() {
    final getIt = GetIt.instance;

    mockClient = MockClient();
    mockSearchController = MockSearchController();
    mockTextEditingController = MockTextEditingController();

    when(mockClient.userID).thenReturn('@me:server.com');
    when(
      mockSearchController.textEditingController,
    ).thenReturn(mockTextEditingController);
    when(mockTextEditingController.text).thenReturn('@test:server.com');

    // Register InvitationStatusMixin dependencies required by
    // ExpansionContactListTile (resolved at field-init time via getIt).
    if (!getIt.isRegistered<HiveGetInvitationStatusInteractor>()) {
      getIt.registerSingleton<HiveGetInvitationStatusInteractor>(
        MockHiveGetInvitationStatusInteractor(),
      );
    }
    if (!getIt.isRegistered<GetInvitationStatusInteractor>()) {
      getIt.registerSingleton<GetInvitationStatusInteractor>(
        MockGetInvitationStatusInteractor(),
      );
    }
    if (!getIt.isRegistered<PostAddressBookInteractor>()) {
      getIt.registerSingleton<PostAddressBookInteractor>(
        MockPostAddressBookInteractor(),
      );
    }
    if (!getIt.isRegistered<HiveDeleteInvitationStatusInteractor>()) {
      getIt.registerSingleton<HiveDeleteInvitationStatusInteractor>(
        MockHiveDeleteInvitationStatusInteractor(),
      );
    }
    if (!getIt.isRegistered<DeleteThirdPartyContactBoxInteractor>()) {
      getIt.registerSingleton<DeleteThirdPartyContactBoxInteractor>(
        MockDeleteThirdPartyContactBoxInteractor(),
      );
    }
  });

  Future<void> buildWidget(
    WidgetTester tester, {
    required String keyword,
  }) async {
    await tester.pumpWidget(
      ThemeBuilder(
        builder: (context, themeMode, primaryColor) => MaterialApp(
          locale: const Locale('en'),
          scrollBehavior: CustomScrollBehavior(),
          localizationsDelegates: const [
            LocaleNamesLocalizationsDelegate(),
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: LocalizationService.supportedLocales,
          theme: TwakeThemes.buildTheme(
            context,
            Brightness.light,
            primaryColor,
          ),
          home: Provider<MatrixState>.value(
            value: FakeMatrixState(mockClient),
            child: Scaffold(
              backgroundColor: LinagoraSysColors.material().onPrimary,
              body: SearchExternalContactWidget(
                keyword: keyword,
                searchController: mockSearchController,
                clientForTesting: mockClient,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('[SearchExternalContactWidget] TEST', () {
    testWidgets('GIVEN getUserProfile is still loading\n'
        'THEN should display CenterLoadingIndicator', (
      WidgetTester tester,
    ) async {
      // getUserProfile returns a Future that never completes → loading state
      final completer = Completer<CachedProfileInformation>();
      when(
        mockClient.getUserProfile(any, maxCacheAge: anyNamed('maxCacheAge')),
      ).thenAnswer((_) => completer.future);

      await buildWidget(tester, keyword: '@test:server.com');
      // Only pump once — do NOT pumpAndSettle, the future is still pending
      await tester.pump();

      expect(find.byType(CenterLoadingIndicator), findsOneWidget);
      expect(find.byType(EmptySearchWidget), findsNothing);
    });

    testWidgets('GIVEN getUserProfile throws an error\n'
        'WHEN searching for @nonexistent:server.com\n'
        'THEN should display EmptySearchWidget (No Results)', (
      WidgetTester tester,
    ) async {
      // thenAnswer with an async error so the exception lands in the Future,
      // not thrown synchronously during _fetchProfileIfNeeded.
      when(
        mockClient.getUserProfile(any, maxCacheAge: anyNamed('maxCacheAge')),
      ).thenAnswer(
        (_) => Future<CachedProfileInformation>.error(
          MatrixException.fromJson({
            'errcode': 'M_NOT_FOUND',
            'error': 'Profile not found',
          }),
        ),
      );

      await buildWidget(tester, keyword: '@nonexistent:server.com');
      await tester.pumpAndSettle();

      expect(find.byType(EmptySearchWidget), findsOneWidget);
      expect(find.byType(CenterLoadingIndicator), findsNothing);
    });

    testWidgets('GIVEN getUserProfile returns a valid profile\n'
        'WHEN searching for @validuser:server.com\n'
        'THEN should display the contact tile with profile info', (
      WidgetTester tester,
    ) async {
      when(
        mockClient.getUserProfile(any, maxCacheAge: anyNamed('maxCacheAge')),
      ).thenAnswer(
        (_) async => CachedProfileInformation.fromProfile(
          ProfileInformation(avatarUrl: null, displayname: 'Valid User'),
          outdated: false,
          updated: DateTime.now(),
        ),
      );

      await buildWidget(tester, keyword: '@validuser:server.com');
      await tester.pumpAndSettle();

      expect(find.byType(EmptySearchWidget), findsNothing);
      expect(find.byType(CenterLoadingIndicator), findsNothing);
      // Should render the ExpansionContactListTile with the fetched profile
      expect(find.byType(ExpansionContactListTile), findsOneWidget);
      // Should show the displayName from the server profile
      expect(find.textContaining('Valid User'), findsOneWidget);
    });
  });
}
