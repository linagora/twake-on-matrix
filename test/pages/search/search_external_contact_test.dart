import 'dart:async';

import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/domain/usecase/contacts/delete_third_party_contact_box_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/get_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/hive_delete_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/hive_get_invitation_status_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:twake_chat/pages/search/search.dart';
import 'package:twake_chat/pages/search/search_external_contact.dart';
import 'package:twake_chat/utils/custom_scroll_behaviour.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/search/empty_search_widget.dart';
import 'package:twake_chat/widgets/theme_builder.dart';
import 'package:twake_chat/widgets/twake_components/twake_loading/center_loading_indicator.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
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

class _FakeMatrixProfileDatasource extends Fake
    implements MatrixProfileDatasource {
  Completer<MatrixUserProfile?> lookup = Completer();
  final freshLookups = <String>[];

  @override
  Future<MatrixUserProfile?> fetchProfile(
    String matrixId, {
    bool fresh = false,
  }) {
    if (fresh) freshLookups.add(matrixId);
    return lookup.future;
  }
}

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<SearchScreenState>(),
  MockSpec<TextEditingController>(),
  MockSpec<HiveGetInvitationStatusInteractor>(),
  MockSpec<GetInvitationStatusInteractor>(),
  MockSpec<PostAddressBookInteractor>(),
  MockSpec<HiveDeleteInvitationStatusInteractor>(),
  MockSpec<DeleteThirdPartyContactBoxInteractor>(),
])
void main() {
  late MockClient mockClient;
  late MockSearchScreenState mockSearchController;
  late MockTextEditingController mockTextEditingController;
  late _FakeMatrixProfileDatasource profileDatasource;

  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton(ResponsiveUtils());
  });

  setUp(() {
    final getIt = GetIt.instance;

    mockClient = MockClient();
    mockSearchController = MockSearchScreenState();
    mockTextEditingController = MockTextEditingController();
    profileDatasource = _FakeMatrixProfileDatasource();

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
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          matrixProfileDatasourceProvider.overrideWithValue(profileDatasource),
        ],
        child: ThemeBuilder(
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('[SearchExternalContactWidget] TEST', () {
    testWidgets('build_whileTheProfileLoads_showsTheLoadingIndicator', (
      WidgetTester tester,
    ) async {
      // Arrange
      profileDatasource.lookup = Completer<MatrixUserProfile?>();

      // Act
      await buildWidget(tester, keyword: '@test:server.com');
      await tester.pump();

      // Assert
      expect(find.byType(CenterLoadingIndicator), findsOneWidget);
      expect(find.byType(EmptySearchWidget), findsNothing);
    });

    testWidgets('build_withAnUnknownMatrixId_showsNoResults', (
      WidgetTester tester,
    ) async {
      // Arrange
      profileDatasource.lookup = Completer<MatrixUserProfile?>()..complete();

      // Act
      await buildWidget(tester, keyword: '@nonexistent:server.com');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EmptySearchWidget), findsOneWidget);
      expect(find.byType(CenterLoadingIndicator), findsNothing);
      expect(profileDatasource.freshLookups, ['@nonexistent:server.com']);
    });

    testWidgets('build_withAKnownMatrixId_showsTheContactTile', (
      WidgetTester tester,
    ) async {
      // Arrange
      profileDatasource.lookup = Completer<MatrixUserProfile?>()
        ..complete(
          const MatrixUserProfile(
            matrixId: '@validuser:server.com',
            displayName: 'Valid User',
          ),
        );

      // Act
      await buildWidget(tester, keyword: '@validuser:server.com');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EmptySearchWidget), findsNothing);
      expect(find.byType(CenterLoadingIndicator), findsNothing);
      expect(find.byType(ExpansionContactListTile), findsOneWidget);
      expect(find.textContaining('Valid User'), findsOneWidget);
    });
  });
}
