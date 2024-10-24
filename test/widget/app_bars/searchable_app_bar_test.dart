import 'package:fluffychat/pages/forward/forward_view_style.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void main() {
  final searchModeNotifier = ValueNotifier(false);
  final textEditingController = TextEditingController();

  Widget makeTestableAppBar({
    bool isFullScreen = true,
    bool displayBackButton = true,
    bool isSearchModeEnabled = false,
  }) {
    searchModeNotifier.value = isSearchModeEnabled;
    getIt.registerSingleton(ResponsiveUtils());

    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: ForwardViewStyle.maxPreferredSize(context),
              child: SearchableAppBar(
                searchModeNotifier: searchModeNotifier,
                title: "Title",
                hintText: "Hint",
                focusNode: FocusNode(),
                textEditingController: textEditingController,
                openSearchBar: () => searchModeNotifier.value = true,
                closeSearchBar: () => searchModeNotifier.value = false,
                isFullScreen: isFullScreen,
                displayBackButton: displayBackButton,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  setUp(() {
    getIt.reset();
  });

  group("fullscreen = false", () {
    testWidgets("Display title and search button", (widgetTester) async {
      await widgetTester.pumpWidget(
        makeTestableAppBar(isFullScreen: false),
      );

      expect(find.text("Title"), findsOneWidget);
      expect(find.text("Hint"), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(
        find.byIcon(
          Icons.chevron_left_outlined,
        ),
        findsNothing,
      );
    });

    testWidgets("Still one textfield when clicking on title",
        (widgetTester) async {
      await widgetTester.pumpWidget(
        makeTestableAppBar(isFullScreen: false),
      );

      await widgetTester.tap(find.text("Title"), warnIfMissed: false);
      await widgetTester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsOneWidget);
    });

    testWidgets("Display back button remove back button", (widgetTester) async {
      await widgetTester.pumpWidget(
        makeTestableAppBar(
          isFullScreen: false,
          displayBackButton: false,
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.search_outlined), findsOneWidget);
    });
  });

  group("fullscreen = true", () {
    testWidgets("Display title and search button (searchMode disabled)",
        (widgetTester) async {
      await widgetTester.pumpWidget(
        makeTestableAppBar(),
      );

      expect(find.text("Title"), findsOneWidget);
      expect(find.text("Hint"), findsNothing);
      expect(find.byIcon(Icons.search_outlined), findsNothing);
      expect(
        find.byIcon(
          Icons.chevron_left_outlined,
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets(
        "Still one textfield when clicking on title (searchMode enabled and search text is empty)",
        (widgetTester) async {
      await widgetTester.pumpWidget(
        makeTestableAppBar(),
      );

      await widgetTester.tap(find.byIcon(Icons.search));
      await widgetTester.pump();

      expect(find.text("Title"), findsNothing);
      expect(find.text("Hint"), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets(
        "Still one textfield when clicking on title (searchMode enabled and search text is not empty)",
        (widgetTester) async {
      await widgetTester.pumpWidget(
        makeTestableAppBar(),
      );

      await widgetTester.tap(find.byIcon(Icons.search));
      textEditingController.text = "Search text";
      await widgetTester.pump();

      expect(find.text("Title"), findsNothing);
      expect(find.text("Hint"), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsNothing);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets("Display title and search button when turning search mode off",
        (widgetTester) async {
      await widgetTester.pumpWidget(
        makeTestableAppBar(
          isSearchModeEnabled: true,
        ),
      );

      await widgetTester.tap(find.byIcon(Icons.close));
      await widgetTester.pump();

      expect(find.text("Title"), findsOneWidget);
      expect(find.text("Hint"), findsNothing);
      expect(find.byIcon(Icons.search_outlined), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(
        find.byIcon(
          Icons.chevron_left_outlined,
        ),
        findsOneWidget,
      );
    });

    testWidgets("change displayBackButton does nothing", (widgetTester) async {
      await widgetTester.pumpWidget(
        makeTestableAppBar(
          displayBackButton: false,
        ),
      );

      expect(find.text("Title"), findsOneWidget);
      expect(find.text("Hint"), findsNothing);
      expect(find.byIcon(Icons.search_outlined), findsNothing);
      expect(
        find.byIcon(
          Icons.chevron_left_outlined,
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
