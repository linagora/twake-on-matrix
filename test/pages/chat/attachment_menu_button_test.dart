import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_config.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/attachment_menu_button.dart';
import 'package:twake_chat/pages/chat/chat_actions.dart';

const _enabled = DriveConfig(ssoUrl: 'https://sso.example', ssoClientId: 'c');
const _disabled = DriveConfig(ssoUrl: '', ssoClientId: 'c');

Future<List<AttachmentMenuAction>> _openMenu(
  WidgetTester tester,
  DriveConfig config,
) async {
  final selected = <AttachmentMenuAction>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [driveConfigProvider.overrideWithValue(config)],
      child: MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(body: AttachmentMenuButton(onSelected: selected.add)),
      ),
    ),
  );
  await tester.tap(find.byType(PopupMenuButton<AttachmentMenuAction>));
  await tester.pumpAndSettle();
  return selected;
}

void main() {
  testWidgets('offers Add from Drive when the homeserver has a Twake SSO', (
    tester,
  ) async {
    await _openMenu(tester, _enabled);

    expect(find.text('Add from Drive'), findsOneWidget);
    expect(find.byType(PopupMenuItem<AttachmentMenuAction>), findsNWidgets(4));
  });

  testWidgets('hides Add from Drive and keeps the other three without one', (
    tester,
  ) async {
    await _openMenu(tester, _disabled);

    expect(find.text('Add from Drive'), findsNothing);
    expect(find.byType(PopupMenuItem<AttachmentMenuAction>), findsNWidgets(3));
  });

  testWidgets('picking Add from Drive reports the drive action', (
    tester,
  ) async {
    final selected = await _openMenu(tester, _enabled);

    await tester.tap(find.text('Add from Drive'));
    await tester.pumpAndSettle();

    expect(selected, [AttachmentMenuAction.drive]);
  });
}
