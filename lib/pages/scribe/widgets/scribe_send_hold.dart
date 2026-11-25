import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/pages/chat/chat_input_row_style.dart';
import 'package:twake_chat/pages/scribe/scribe_controller.dart';

/// Holds the composer's send button, dimmed, while the Scribe rewrites the
/// room's draft: the draft is about to change.
class ScribeSendHold extends ConsumerWidget {
  const ScribeSendHold({super.key, required this.roomId, required this.child});

  final String roomId;

  /// The send button.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRewriting = ref.watch(scribeControllerProvider(roomId));
    return IgnorePointer(
      ignoring: isRewriting,
      child: Opacity(
        opacity: isRewriting ? ChatInputRowStyle.inputComposerOpacity : 1,
        child: child,
      ),
    );
  }
}
