import 'package:fluffychat/presentation/extensions/text_editting_controller_extension.dart';
import 'package:fluffychat/utils/one_time_debouncer.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as flutter;
import 'package:matrix/matrix.dart';

class InputBarShortcuts extends StatelessWidget {
  final Widget child;

  final TextEditingController? controller;

  final Room? room;

  final VoidCallback handlePaste;

  final ValueChanged<String>? onSubmitted;

  InputBarShortcuts({
    super.key,
    required this.child,
    required this.handlePaste,
    this.room,
    this.controller,
    this.onSubmitted,
  });

  final _debouncer = OneTimeDebouncer(milliseconds: 50);

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(
          flutter.LogicalKeyboardKey.keyV,
          meta: PlatformInfos.isMacKeyboardPlatform,
          control: !PlatformInfos.isMacKeyboardPlatform,
        ): () async {
          handlePaste();
        },
        const SingleActivator(
          flutter.LogicalKeyboardKey.keyC,
          meta: true,
        ): () {
          controller?.copyText();
        },
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
          onSubmitted?.call(controller?.text ?? '');
        }
      },
      child: child,
    );
  }
}
