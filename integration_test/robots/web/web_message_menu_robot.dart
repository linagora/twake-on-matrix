import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../base/core_robot.dart';
import '../abstract/abstract_message_menu_robot.dart';

/// Web/desktop message action menu.
///
/// The mobile long-press `PullDownMenu` is gated behind
/// `ResponsiveUtils.isMobile`, so on web it never appears. Instead, hovering a
/// message bubble (a `MouseRegion` on the message container) reveals a
/// horizontal action bar of `TwakeIconButton`s — reaction / reply / more.
///
/// `reply` is a first-class bar button (tapped directly via its tooltip).
/// Everything else (forward, copy, edit, select, delete, …) lives behind the
/// "more" button ([Icons.more_horiz]), which opens a context menu of
/// [ContextMenuActionItemWidget]s (NOT a `PullDownMenu` — that path is
/// mobile-only). Reply is intentionally absent from that overflow menu, so it
/// must be taken from the bar.
class WebMessageMenuRobot extends CoreRobot
    implements AbstractMessageMenuRobot {
  WebMessageMenuRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).last))!;

  /// Moves a synthetic mouse pointer over the bubble for [message] so the
  /// container's `MouseRegion` fires and the action bar (gated on
  /// `isHoverNotifier`) renders. Returns the live gesture — the caller removes
  /// it once the bar interaction is done.
  Future<TestGesture> _hover(String message) async {
    final bubble = $(
      MessageContent,
    ).containing(find.textContaining(message, findRichText: true)).first;
    await $.waitUntilVisible(bubble);

    final center = $.tester.getCenter(bubble.finder);
    final gesture = await $.tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: center);
    await $.pump();
    await gesture.moveTo(center);
    await $.pump(const Duration(milliseconds: 300));
    return gesture;
  }

  /// Hovers [message], opens the "more" context menu and taps the row whose
  /// label is [itemLabel].
  Future<void> _tapOverflowItem(String message, String itemLabel) async {
    final gesture = await _hover(message);

    // All overflow actions live behind the "more" button; open it, then tap
    // the row labelled [itemLabel].
    final moreButton = $(
      TwakeIconButton,
    ).containing(find.byIcon(Icons.more_horiz));
    await $.waitUntilVisible(moreButton, timeout: const Duration(seconds: 5));
    await $.tester.tap(moreButton.finder);
    await gesture.removePointer();

    final item = $(
      ContextMenuActionItemWidget,
    ).containing(find.text(itemLabel));
    await $.waitUntilVisible(item, timeout: const Duration(seconds: 10));
    await $.tester.tap(item.finder);
    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndTrySettle();
  }

  @override
  Future<void> openForward(String message) async {
    await _tapOverflowItem(message, _l10n.forward);
    await $.waitUntilExists(
      $(ForwardView),
      timeout: const Duration(seconds: 15),
    );
  }

  @override
  Future<void> openReply(String message) async {
    final gesture = await _hover(message);
    // Reply is a first-class bar button (it is not in the "more" menu).
    final replyButton = $(
      TwakeIconButton,
    ).containing(find.byTooltip(_l10n.reply));
    await $.waitUntilVisible(replyButton, timeout: const Duration(seconds: 5));
    await $.tester.tap(replyButton.finder);
    await gesture.removePointer();
    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndTrySettle();
  }

  @override
  Future<void> openDelete(String message) async {
    await _tapOverflowItem(message, _l10n.delete);
    // The single-message delete confirmation is `deleteEventAction`'s
    // `showConfirmAlertDialog`, whose OK button is labelled `L10n.delete`.
    // Flutter Web reports the host platform, so on macOS it renders a Cupertino
    // dialog rather than a Material `AlertDialog` — match the button by label,
    // skipping the now-popped menu item with `.last`.
    final confirm = $(find.text(_l10n.delete));
    await $.waitUntilVisible(confirm, timeout: const Duration(seconds: 10));
    await confirm.last.tap();
    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndTrySettle();
  }
}
