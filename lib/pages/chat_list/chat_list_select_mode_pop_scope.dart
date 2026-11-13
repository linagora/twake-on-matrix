import 'package:flutter/material.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';

class ChatListSelectModePopScope extends StatelessWidget {
  final ValueNotifier<SelectMode> selectModeNotifier;
  final VoidCallback onLeaveSelectMode;
  final Widget child;

  const ChatListSelectModePopScope({
    super.key,
    required this.selectModeNotifier,
    required this.onLeaveSelectMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SelectMode>(
      valueListenable: selectModeNotifier,
      builder: (context, selectMode, child) => PopScope(
        canPop: !selectMode.isSelectMode,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && selectMode.isSelectMode) onLeaveSelectMode();
        },
        child: child!,
      ),
      child: child,
    );
  }
}
