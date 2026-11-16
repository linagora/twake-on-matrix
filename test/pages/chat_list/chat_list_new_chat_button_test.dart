import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_list/chat_list_new_chat_button.dart';

// The pen of the Discussions app bar: ChatListNewChatButton(controller:),
// with Key('new_chat_pen') on the icon button.

class _FakeController extends Fake implements ChatListController {
  final calls = <String>[];

  @override
  void goToNewPrivateChat() => calls.add('direct');

  @override
  void goToNewGroupChat(BuildContext context, {String? parentSpaceId}) =>
      calls.add('group');

  @override
  void goToNewFeed(BuildContext context) => calls.add('feed');

  @override
  void goToNewSpace(BuildContext context, {String? parentSpaceId}) =>
      calls.add('space');

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeController';
}

const _pen = Key('new_chat_pen');

void main() {
  setUp(() {
    // KeyBoardShortcuts uses a VisibilityDetector, whose timer would stay pending.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  late _FakeController controller;

  Future<void> pumpPen(WidgetTester tester, {required double width}) async {
    final singleColumn = width < 905;
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    controller = _FakeController();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            actions: [
              ChatListNewChatButton(
                controller: controller,
                isSingleColumn: singleColumn,
              ),
            ],
          ),
        ),
      ),
    );
    // KeyBoardShortcuts starts a timer when it is first built.
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  group('new chat pen', () {
    testWidgets('is a bare pen icon, with no container around it', (
      tester,
    ) async {
      await pumpPen(tester, width: 400);

      expect(find.byKey(_pen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(_pen),
          matching: find.byIcon(Icons.mode_edit_outline_outlined),
        ),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(_pen),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('on a single column opens a new direct message at once', (
      tester,
    ) async {
      await pumpPen(tester, width: 400);

      await tester.tap(find.byKey(_pen));
      await tester.pumpAndSettle();

      expect(controller.calls, ['direct']);
      expect(find.text('New Group Chat'), findsNothing);
    });

    testWidgets('on a wide layout opens a menu of the four creations', (
      tester,
    ) async {
      await pumpPen(tester, width: 1300);

      await tester.tap(find.byKey(_pen));
      await tester.pumpAndSettle();

      expect(controller.calls, isEmpty);
      expect(
        tester.getRect(find.byType(MenuItemButton).first).top,
        greaterThanOrEqualTo(tester.getRect(find.byKey(_pen)).bottom),
        reason: 'the menu opens under the pen, not over it',
      );
      expect(find.text('New direct message'), findsOneWidget);
      expect(find.text('New Group Chat'), findsOneWidget);
      expect(find.text('New Feed'), findsOneWidget);
      expect(find.text('New space'), findsOneWidget);
    });

    testWidgets('on a wide layout each menu entry does its own creation', (
      tester,
    ) async {
      await pumpPen(tester, width: 1300);
      for (final entry in {
        'New direct message': 'direct',
        'New Group Chat': 'group',
        'New Feed': 'feed',
        'New space': 'space',
      }.entries) {
        await tester.tap(find.byKey(_pen));
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(controller.calls.last, entry.value);
      }
    });

    testWidgets('Ctrl+N still opens a new direct message', (tester) async {
      await pumpPen(tester, width: 400);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(controller.calls, ['direct']);
    });
  });
}
