import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/message_content.dart';
import 'package:twake_chat/pages/forward/forward_view.dart';
import 'package:twake_chat/widgets/context_menu/context_menu_action_item_widget.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../base/core_robot.dart';
import '../abstract/abstract_message_menu_robot.dart';
import '../message_selection_appbar_helper.dart';

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

  /// Hovers the bubble for [message] and keeps the synthetic mouse pointer over
  /// it until [target] is visible, returning the live gesture — the caller
  /// removes it once the bar interaction is done.
  ///
  /// The action bar is gated on a `MouseRegion`-driven hover notifier, and a
  /// single synthetic hover is dropped whenever the message list rebuilds right
  /// after send (the optimistic event is replaced once the server acks, which
  /// detaches the hovered region while the pointer stays still). Hovering once
  /// and waiting therefore races the ack — exactly like the mobile long-press
  /// path — so re-issue the hover until the bar actually renders.
  Future<TestGesture> _hoverUntilVisible(
    String message,
    PatrolFinder target, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final bubble = $(
      MessageContent,
    ).containing(find.textContaining(message, findRichText: true)).first;
    await $.waitUntilVisible(bubble, timeout: timeout);

    final gesture = await $.tester.createGesture(kind: PointerDeviceKind.mouse);

    var isPointerAdded = false;
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      // Re-read the bubble position every attempt: the list can scroll or the
      // message can be rebuilt once the server acks, moving the bubble.
      final center = bubble.exists ? $.tester.getCenter(bubble.finder) : null;
      if (center == null) {
        await $.pump(const Duration(milliseconds: 100));
        continue;
      }

      if (!isPointerAdded) {
        await gesture.addPointer(location: center);
        isPointerAdded = true;
      }
      await gesture.moveTo(center);
      await $.pump(const Duration(milliseconds: 200));
      if (target.visible) {
        return gesture;
      }

      // Leave and re-enter the bubble so the `MouseRegion` fires again if the
      // message was rebuilt while the pointer stayed still.
      await gesture.moveTo(Offset(center.dx, center.dy - 300));
      await $.pump(const Duration(milliseconds: 100));
    }

    if (isPointerAdded) {
      await gesture.removePointer();
    }
    throw StateError(
      'The message action bar for "$message" did not appear within $timeout.',
    );
  }

  /// Hovers [message], opens the "more" context menu and taps the row whose
  /// label is [itemLabel].
  Future<void> _tapOverflowItem(String message, String itemLabel) async {
    // All overflow actions live behind the "more" button; open it, then tap
    // the row labelled [itemLabel].
    final moreButton = $(
      TwakeIconButton,
    ).containing(find.byIcon(Icons.more_horiz));
    final gesture = await _hoverUntilVisible(message, moreButton);
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
    // Reply is a first-class bar button (it is not in the "more" menu).
    final replyButton = $(
      TwakeIconButton,
    ).containing(find.byTooltip(_l10n.reply));
    final gesture = await _hoverUntilVisible(message, replyButton);
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

  @override
  Future<void> openEdit(String message) async {
    await _tapOverflowItem(message, _l10n.edit);
  }

  @override
  Future<void> openSelect(String message) async {
    await _tapOverflowItem(message, _l10n.select);
  }

  @override
  Future<void> openMessageInfo(String message) async {
    await openSelect(message);
    await openMessageInfoFromSelectionAppBar($, _l10n);
  }
}
