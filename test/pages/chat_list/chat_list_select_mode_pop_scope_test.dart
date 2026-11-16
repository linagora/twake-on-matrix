import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat_list/chat_list_select_mode_pop_scope.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';

void main() {
  late ValueNotifier<SelectMode> selectModeNotifier;

  setUp(() {
    selectModeNotifier = ValueNotifier(SelectMode.normal);
  });

  tearDown(() {
    selectModeNotifier.dispose();
  });

  Future<void> pumpChatListRoute(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChatListSelectModePopScope(
                  selectModeNotifier: selectModeNotifier,
                  onLeaveSelectMode: () =>
                      selectModeNotifier.value = SelectMode.normal,
                  child: const Text('chat list'),
                ),
              ),
            ),
            child: const Text('previous page'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('previous page'));
    await tester.pumpAndSettle();
  }

  testWidgets('GIVEN select mode\n'
      'WHEN back is pressed\n'
      'THEN select mode is left and the chat list stays', (tester) async {
    await pumpChatListRoute(tester);
    selectModeNotifier.value = SelectMode.select;
    await tester.pump();

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(selectModeNotifier.value, SelectMode.normal);
    expect(find.text('chat list'), findsOneWidget);
  });

  testWidgets('GIVEN normal mode\n'
      'WHEN back is pressed\n'
      'THEN the route pops as before', (tester) async {
    await pumpChatListRoute(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(selectModeNotifier.value, SelectMode.normal);
    expect(find.text('chat list'), findsNothing);
    expect(find.text('previous page'), findsOneWidget);
  });
}
