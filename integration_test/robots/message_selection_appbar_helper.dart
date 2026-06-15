import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/event_info_dialog.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// Shared selection-mode app-bar interaction, identical on mobile and web once
/// a message is selected: tap the app-bar "More" (`Icons.more_vert`) button,
/// then the "Message info" row in the overflow context menu, leaving the
/// [EventInfoDialog] on screen.
///
/// Lives outside the per-platform message-menu robots because the app bar is
/// the same widget tree on both — only *entering* selection mode differs.
///
/// The "More" button exists in two responsive layout branches (narrow + wide),
/// so the off-stage copy is filtered out with `hitTestable()` — tapping it
/// would open the context-menu dialog off-screen and the rows would never
/// become visible.
Future<void> openMessageInfoFromSelectionAppBar(
  PatrolIntegrationTester $,
  L10n l10n,
) async {
  final more = find.byIcon(Icons.more_vert).hitTestable();
  await $.waitUntilVisible($(more), timeout: const Duration(seconds: 5));
  await $.tester.tap(more.first);
  await $.pumpAndSettle();

  final info = $(
    ContextMenuActionItemWidget,
  ).containing(find.text(l10n.messageInfo));
  await $.waitUntilVisible(info, timeout: const Duration(seconds: 10));
  await info.tap();

  await $.waitUntilVisible(
    $(EventInfoDialog),
    timeout: const Duration(seconds: 10),
  );
}
