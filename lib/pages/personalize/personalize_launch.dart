import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/pages/chat/chat_input_row_style.dart';
import 'package:twake_chat/pages/personalize/personalize_flow.dart';
import 'package:twake_chat/providers/personalization/personalize_steps_controller.dart';

/// Asks the personalization steps this device has not seen: once per run of
/// the app, after the first sync.
abstract final class PersonalizeLaunch {
  static bool _asked = false;

  /// Waits for [firstSync], then opens the flow over [context] with the
  /// steps pending for the width of its screen, if there are any.
  static Future<void> afterFirstSync(
    BuildContext context, {
    required Future<void> firstSync,
  }) async {
    if (_asked) return;
    _asked = true;
    await firstSync;
    if (!context.mounted) return;
    final steps = await ProviderScope.containerOf(context, listen: false)
        .read(personalizeStepsControllerProvider.notifier)
        .pending(isWide: !ChatInputRowStyle.responsiveUtils.isMobile(context));
    if (steps.isEmpty || !context.mounted) return;
    // A page, not a dialog: full screen with its own bar, and the system back
    // closes it like the close button.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PersonalizeFlow(steps: steps),
      ),
    );
  }

  @visibleForTesting
  static void resetForTesting() => _asked = false;
}
