import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/twake_components/twake_header.dart';

import 'chat_list_header_test_harness.dart';

/// `NavigationKeys.settingsAvatar`: the avatar of the user in the phone app
/// bar of Chats, Contacts and Activity.
const _avatar = Key('navigation.settingsAvatar');

bool _avatarFocused() {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  var found = focused.widget.key == _avatar;
  focused.visitAncestorElements((element) {
    found = found || element.widget.key == _avatar;
    return !found;
  });
  return found;
}

void main() {
  setUpHeaderTests();
  _withoutSearchField();
  _settingsAvatar();
}

void _withoutSearchField() {
  group('[ChatList] phone header without a search field', () {
    testWidgets('GIVEN a phone\n'
        'THEN the header has no search field', (tester) async {
      await HeaderHarness.pump(tester, const HeaderView.phone());

      expect(
        find.descendant(of: headerFinder, matching: find.byType(TextField)),
        findsNothing,
      );
    });

    testWidgets('GIVEN a wide screen\n'
        'THEN the header keeps its search field', (tester) async {
      await HeaderHarness.pump(tester, const HeaderView.wide());

      expect(
        find.descendant(of: headerFinder, matching: find.byType(TextField)),
        findsOneWidget,
      );
    });
  });
}

void _settingsAvatar() {
  group('[ChatList] settings avatar', () {
    _avatarShown();
    _avatarOpensSettings();
    _avatarHidden();
  });
}

void _avatarShown() {
  testWidgets('GIVEN a phone\n'
      'THEN the avatar of the user sits at the start of the app bar', (
    tester,
  ) async {
    await HeaderHarness.pump(tester, const HeaderView.phoneWithStatusBar());

    expect(find.byKey(_avatar), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(_avatar), matching: find.byType(Avatar)),
      findsOneWidget,
    );
    final avatar = tester.getRect(find.byKey(_avatar));
    final appBar = tester.getRect(find.byType(TwakeHeader));
    expect(avatar.right, lessThan(tester.getRect(find.text('Chats')).left));
    expect(avatar.left, greaterThanOrEqualTo(0));
    expect(avatar.top, greaterThanOrEqualTo(statusBar));
    expect(avatar.bottom, lessThanOrEqualTo(appBar.bottom));
  });

  testWidgets('GIVEN a phone\n'
      'THEN a screen reader hears the avatar as « Settings »', (tester) async {
    await HeaderHarness.pump(tester, const HeaderView.phone());

    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
  });
}

void _avatarOpensSettings() {
  testWidgets('GIVEN a phone\n'
      'WHEN the avatar is tapped\n'
      'THEN Settings opens', (tester) async {
    final h = await HeaderHarness.pump(tester, const HeaderView.phone());

    await tester.tap(find.byKey(_avatar));
    await tester.pump();

    expect(h.controller.settingsOpened, 1);
  });

  testWidgets('GIVEN a phone with a hardware keyboard\n'
      'WHEN Tab reaches the avatar and Enter is pressed\n'
      'THEN Settings opens', (tester) async {
    final h = await HeaderHarness.pump(tester, const HeaderView.phone());

    for (var i = 0; i < 20 && !_avatarFocused(); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(_avatarFocused(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(h.controller.settingsOpened, 1);
  });
}

void _avatarHidden() {
  testWidgets('GIVEN select mode\n'
      'THEN the avatar is hidden', (tester) async {
    final h = await HeaderHarness.pump(tester, const HeaderView.phone());

    await h.startSelectMode(tester);

    expect(find.byKey(_avatar), findsNothing);
  });

  testWidgets('GIVEN a wide screen\n'
      'THEN the app bar has no avatar', (tester) async {
    await HeaderHarness.pump(tester, const HeaderView.wide());

    expect(find.byKey(_avatar), findsNothing);
  });
}
