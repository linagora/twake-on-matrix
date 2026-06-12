import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
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
/// horizontal bar of `TwakeIconButton`s — reaction / reply / forward / more —
/// each identified by its localized tooltip
/// (`ChatHorizontalActionMenu.getTitle`). Forward is a first-class button in
/// the bar, so it is tapped directly without going through "more".
class WebMessageMenuRobot extends CoreRobot
    implements AbstractMessageMenuRobot {
  WebMessageMenuRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).last))!;

  @override
  Future<void> openForward(String message) async {
    // The action bar only renders while the bubble is hovered (its visibility
    // is driven by an `isHoverNotifier == event.eventId`), so move a synthetic
    // mouse pointer over the bubble before looking for the Forward button.
    final bubble = $(
      MessageContent,
    ).containing(find.textContaining(message, findRichText: true));
    await $.waitUntilVisible(bubble);

    final gesture = await $.tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo($.tester.getCenter(bubble.finder));
    await $.pump();

    final forwardButton = $(
      TwakeIconButton,
    ).containing(find.byTooltip(_l10n.forward));
    await $.waitUntilVisible(
      forwardButton,
      timeout: const Duration(seconds: 5),
    );
    await $.tester.tap(forwardButton.finder);
    await gesture.removePointer();

    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndTrySettle();

    await $.waitUntilExists(
      $(ForwardView),
      timeout: const Duration(seconds: 15),
    );
  }
}
