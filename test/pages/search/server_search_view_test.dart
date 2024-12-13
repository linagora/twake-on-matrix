import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/search/search_contacts_and_chats_controller.dart';
import 'package:fluffychat/pages/search/server_search_controller.dart';
import 'package:fluffychat/pages/search/server_search_view.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_empty_search.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_state.dart';
import 'package:fluffychat/utils/custom_scroll_behaviour.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:mockito/mockito.dart';
import 'server_search_view_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SearchController>(),
  MockSpec<ServerSearchController>(),
  MockSpec<TextEditingController>(),
  MockSpec<SearchContactsAndChatsController>(),
])
void main() {
  late final SearchController mockSearchController;
  late final ServerSearchController mockServerSearchController;
  late final TextEditingController mockTextEditingController;
  late final SearchContactsAndChatsController
      mockSearchContactAndRecentChatController;

  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton(ResponsiveUtils());
    mockSearchController = MockSearchController();
    mockServerSearchController = MockServerSearchController();
    mockTextEditingController = MockTextEditingController();
    mockSearchContactAndRecentChatController =
        MockSearchContactsAndChatsController();
  });

  Future<void> makeTestable(WidgetTester tester) async {
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
          home: Scaffold(
            backgroundColor: LinagoraSysColors.material().onPrimary,
            body: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                ServerSearchMessagesList(
                  searchController: mockSearchController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('[ServerSearchMessagesList] TEST', () {
    group('GIVEN searchResultsNotifier is PresentationServerSideEmptySearch',
        () {
      testWidgets(
        'GIVEN notifier value is empty\n'
        'AND recentAndContactsNotifier value is empty\n'
        'AND keyword is a Matrix ID\n'
        'THEN should display SizedBox.shrink\n',
        (WidgetTester tester) async {
          when(mockSearchController.serverSearchController)
              .thenReturn(mockServerSearchController);
          when(mockSearchController.textEditingController)
              .thenReturn(mockTextEditingController);
          when(mockSearchController.searchContactAndRecentChatController)
              .thenReturn(
            mockSearchContactAndRecentChatController,
          );
          when(mockTextEditingController.text).thenReturn('@test:domain.com');
          when(mockServerSearchController.searchResultsNotifier).thenReturn(
            ValueNotifier<PresentationServerSideUIState>(
              PresentationServerSideEmptySearch(),
            ),
          );
          when(
            mockSearchContactAndRecentChatController.recentAndContactsNotifier,
          ).thenReturn(ValueNotifier<List<PresentationSearch>>([]));

          await makeTestable(tester);

          expect(find.byType(SizedBox), findsOneWidget);

          final SizedBox foundSizedBox =
              tester.firstWidget(find.byType(SizedBox));
          expect(foundSizedBox.child, isNull);
          expect(foundSizedBox.width, equals(0));
          expect(foundSizedBox.height, equals(0));
        },
      );

      testWidgets(
        'GIVEN searchResultsNotifier value is empty\n'
        'AND recentAndContactsNotifier value is empty\n'
        'AND keyword is not a Matrix ID\n'
        'THEN should display EmptySearchWidget\n',
        (WidgetTester tester) async {
          when(mockSearchController.serverSearchController)
              .thenReturn(mockServerSearchController);
          when(mockSearchController.textEditingController)
              .thenReturn(mockTextEditingController);
          when(mockSearchController.searchContactAndRecentChatController)
              .thenReturn(
            mockSearchContactAndRecentChatController,
          );
          when(mockTextEditingController.text).thenReturn('test');
          when(mockServerSearchController.searchResultsNotifier).thenReturn(
            ValueNotifier<PresentationServerSideUIState>(
              PresentationServerSideEmptySearch(),
            ),
          );
          when(
            mockSearchContactAndRecentChatController.recentAndContactsNotifier,
          ).thenReturn(ValueNotifier<List<PresentationSearch>>([]));

          await makeTestable(tester);
          await tester.pumpAndSettle();

          expect(find.byType(EmptySearchWidget), findsOneWidget);
        },
      );
    });
  });
}
