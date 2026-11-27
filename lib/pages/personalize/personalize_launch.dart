import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/pages/chat/chat_input_row_style.dart';
import 'package:twake_chat/pages/personalize/personalize_flow.dart';
import 'package:twake_chat/providers/personalization/personalize_steps_controller.dart';

/// Asks the personalization steps this device has not seen: once per run of
/// the app. The caller runs it once the first sync is done.
abstract final class PersonalizeLaunch {
  static bool _asked = false;

  /// Opens the flow over [context] with the steps pending for the width of its
  /// screen, if there are any. On a phone the flow never opens over a chat
  /// (the start from a notification or a share leaves one on top of the list):
  /// it waits until the chat list is the top route again. On a wide screen the
  /// list stays visible beside the chat, so it opens at once.
  static Future<void> afterFirstSync(BuildContext context) async {
    if (_asked) return;
    _asked = true;
    final controller = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(personalizeStepsControllerProvider.notifier);
    // The width is read once the storage has answered: it may have changed.
    await controller.pending(isWide: true);
    if (!context.mounted) return;
    final isMobile = ChatInputRowStyle.responsiveUtils.isMobile(context);
    final steps = await controller.pending(isWide: !isMobile);
    if (steps.isEmpty || !context.mounted) return;
    if (isMobile) await _untilOnTop(context);
    if (!context.mounted) return;
    // A page, not a dialog: full screen with its own bar, and the system back
    // closes it like the close button.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PersonalizeFlow(steps: steps),
      ),
    );
  }

  /// Completes once the route of [context] is the top route: at once if it is,
  /// else when the route that covers it has left (its animation back to
  /// dismissed).
  static Future<void> _untilOnTop(BuildContext context) async {
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) return;
    final covering = route.secondaryAnimation;
    if (covering == null) return;
    final onTop = Completer<void>();
    void listener(AnimationStatus status) {
      if (onTop.isCompleted) return;
      if (status == AnimationStatus.dismissed && route.isCurrent) {
        onTop.complete();
      }
    }

    covering.addStatusListener(listener);
    await onTop.future;
    covering.removeStatusListener(listener);
  }

  @visibleForTesting
  static void resetForTesting() => _asked = false;
}
