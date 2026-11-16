import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:twake_chat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_components/twake_header.dart';

// TwakeHeader shows its `actions` in the app bar of the normal mode only; the
// pen of the chat list (Key('new_chat_pen')) is passed there.

class _FakeClient extends Fake implements Client {
  @override
  final CachedStreamController<BasicEvent> onAccountData =
      CachedStreamController();
}

class _FakeMatrix extends Fake implements MatrixState {
  _FakeMatrix(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

const _pen = Key('new_chat_pen');

void main() {
  setUp(() => GetIt.instance.registerSingleton(ResponsiveUtils()));
  tearDown(() => GetIt.instance.reset());

  late List<String> calls;
  late ValueNotifier<SelectMode> selectMode;

  Future<void> pumpHeader(
    WidgetTester tester, {
    required double width,
    SelectMode mode = SelectMode.normal,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    calls = [];
    selectMode = ValueNotifier(mode);
    addTearDown(selectMode.dispose);
    final selection = ValueNotifier<List<ConversationSelectionPresentation>>(
      const [],
    );
    addTearDown(selection.dispose);
    final client = _FakeClient();
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
              appBar: TwakeHeader(
                onClearSelection: () {},
                client: client,
                selectModeNotifier: selectMode,
                conversationSelectionNotifier: selection,
                onClickAvatar: () {},
                actions: [
                  IconButton(
                    key: _pen,
                    icon: const Icon(Icons.mode_edit_outline_outlined),
                    onPressed: () => calls.add('direct'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('new chat pen in the Discussions app bar', () {
    testWidgets('is in the app bar, next to the title, as a bare icon', (
      tester,
    ) async {
      await pumpHeader(tester, width: 400);

      final inBar = find.descendant(
        of: find.byType(AppBar),
        matching: find.byKey(_pen),
      );
      expect(inBar, findsOneWidget);
      expect(
        find.descendant(
          of: inBar,
          matching: find.byIcon(Icons.mode_edit_outline_outlined),
        ),
        findsOneWidget,
      );
      expect(find.text('Chats'), findsOneWidget);
      // No container, background or shadow drawn around it.
      expect(
        find.descendant(of: inBar, matching: find.byType(DecoratedBox)),
        findsNothing,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('is hidden in select mode', (tester) async {
      await pumpHeader(tester, width: 400, mode: SelectMode.select);

      expect(find.byKey(_pen), findsNothing);
      expect(find.byIcon(Icons.mode_edit_outline_outlined), findsNothing);
    });

    testWidgets('comes back when select mode ends', (tester) async {
      await pumpHeader(tester, width: 400, mode: SelectMode.select);

      selectMode.value = SelectMode.normal;
      await tester.pump();

      expect(find.byKey(_pen), findsOneWidget);
    });
  });
}
