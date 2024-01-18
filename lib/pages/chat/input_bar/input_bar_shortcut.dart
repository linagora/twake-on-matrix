import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/presentation/extensions/text_editting_controller_extension.dart';
import 'package:fluffychat/utils/one_time_debouncer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as flutter;
import 'package:matrix/matrix.dart';

class InputBarShortcuts extends StatelessWidget {
  final Widget child;

  final TextEditingController? controller;

  final Room? room;

  final ValueChanged<String>? onEnter;

  final FocusSuggestionController? focusSuggestionController;

  InputBarShortcuts({
    super.key,
    required this.child,
    this.room,
    this.controller,
    this.onEnter,
    this.focusSuggestionController,
  });

  final _debouncer = OneTimeDebouncer(milliseconds: 50);

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(
          flutter.LogicalKeyboardKey.enter,
          shift: true,
        ): () {
          _debouncer.run(() {
            controller?.addNewLine();
          });
        },
        const SingleActivator(
          flutter.LogicalKeyboardKey.enter,
        ): () {
          onEnter?.call(controller?.text ?? '');
        },
      },
      child: child,
    );
  }
}
