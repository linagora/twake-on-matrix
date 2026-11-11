import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/extensions/chat/copy_message_link_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

void main() {
  const link = 'https://matrix.to/#/!abc%3Aexample.org/%24evt';
  // The English texts of twake-space-chat (chat.linkCopied, chat.linkToCopy).
  const linkCopied = 'Link copied';
  const linkToCopy = 'Copy this link: $link';
  String? copiedText;

  setUpAll(() {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton(ResponsiveUtils());
    }
  });

  setUp(() => copiedText = null);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  void mockClipboard({required bool fails}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method != 'Clipboard.setData') return null;
          if (fails) {
            throw PlatformException(code: 'clipboard-unavailable');
          }
          copiedText = (call.arguments as Map)['text'] as String?;
          return null;
        });
  }

  Future<void> tapCopy(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.copyMessageLink(link),
              child: const Text('copy'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('copy'));
    await tester.pumpAndSettle();
  }

  testWidgets('copies the link and says "Link copied", as the web app', (
    tester,
  ) async {
    mockClipboard(fails: false);

    await tapCopy(tester);

    expect(copiedText, link);
    expect(find.text(linkCopied), findsOneWidget);
    expect(find.text(linkToCopy), findsNothing);
  });

  testWidgets('shows the link to copy by hand when the clipboard fails', (
    tester,
  ) async {
    mockClipboard(fails: true);

    await tapCopy(tester);

    expect(copiedText, isNull);
    expect(find.text(linkToCopy), findsOneWidget);
    expect(find.text(linkCopied), findsNothing);
  });

  testWidgets(
    'shows nothing when the caller is gone before the copy finishes',
    (tester) async {
      final clipboardWrite = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') await clipboardWrite.future;
            return null;
          });
      final showButton = ValueNotifier(true);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: showButton,
              builder: (_, visible, _) => visible
                  ? Builder(
                      builder: (context) => TextButton(
                        onPressed: () => context.copyMessageLink(link),
                        child: const Text('copy'),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      );
      await tester.tap(find.text('copy'));
      await tester.pump();
      showButton.value = false;
      await tester.pump();

      clipboardWrite.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(linkCopied), findsNothing);
    },
  );
}
