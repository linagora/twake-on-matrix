import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/events/message/message_context_menu_action.dart';

void main() {
  testWidgets('tapping Copy link closes the menu with copyLink', (
    tester,
  ) async {
    Object? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<Object?>(
                MaterialPageRoute<Object?>(
                  builder: (menuContext) => TextButton(
                    onPressed: () =>
                        MessageContextMenuAction.copyLink.onTap(menuContext),
                    child: const Text('menu'),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('menu'));
    await tester.pumpAndSettle();

    // Message turns this result into widget.onCopyLink.
    expect(result, 'copyLink');
  });
}
