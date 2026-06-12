import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../base/core_robot.dart';
import '../abstract/abstract_message_menu_robot.dart';

/// Web/desktop message action menu.
///
/// The mobile long-press `PullDownMenu` is gated behind
/// `ResponsiveUtils.isMobile`, so on web it never appears. Instead, hovering a
/// message bubble (a `MouseRegion` on the message container) reveals a
/// horizontal bar of `TwakeIconButton`s — reaction / reply / forward / more.
///
/// Forward is a first-class bar action ([Icons.shortcut]); when the viewport
/// is too narrow the `OverflowView` collapses it behind the "more" button
/// ([Icons.more_horiz]), which opens a context-menu dialog of
/// [ContextMenuActionItemWidget]s. We handle both cases so the test is
/// width-independent.
class WebMessageMenuRobot extends CoreRobot
    implements AbstractMessageMenuRobot {
  WebMessageMenuRobot(super.$);

  static const _forwardIcon = Icons.shortcut;
  static const _moreIcon = Icons.more_horiz;

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).last))!;

  PatrolFinder _barButton(IconData icon) =>
      $(TwakeIconButton).containing(find.byIcon(icon));

  @override
  Future<void> openForward(String message) async {
    final bubble = $(
      MessageContent,
    ).containing(find.textContaining(message, findRichText: true)).first;
    await $.waitUntilVisible(bubble);

    // Move a synthetic mouse pointer over the bubble so the container's
    // MouseRegion fires and the action bar (gated on `isHoverNotifier`) renders.
    final center = $.tester.getCenter(bubble.finder);
    final gesture = await $.tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: center);
    await $.pump();
    await gesture.moveTo(center);
    await $.pump(const Duration(milliseconds: 300));

    final forwardButton = _barButton(_forwardIcon);
    final moreButton = _barButton(_moreIcon);

    // Wait for the bar to surface (either Forward directly or the More overflow).
    await $.waitUntilVisible(
      forwardButton.exists ? forwardButton : moreButton,
      timeout: const Duration(seconds: 5),
    );

    if (forwardButton.exists) {
      // Bar action callbacks are wired to InkWell.onTapDown — a normal tap
      // (down + up) triggers it.
      await $.tester.tap(forwardButton.finder);
    } else {
      // Forward collapsed into the overflow context-menu dialog: open it, then
      // tap the Forward row.
      await $.tester.tap(moreButton.finder);
      final forwardItem = $(
        ContextMenuActionItemWidget,
      ).containing(find.text(_l10n.forward));
      await $.waitUntilVisible(
        forwardItem,
        timeout: const Duration(seconds: 10),
      );
      await $.tester.tap(forwardItem.finder);
    }
    await gesture.removePointer();

    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndTrySettle();

    await $.waitUntilExists(
      $(ForwardView),
      timeout: const Duration(seconds: 15),
    );
  }
}
