import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:flutter/material.dart';

class ChatSortLoading extends StatelessWidget {
  const ChatSortLoading({super.key, this.controller});

  final ChatListController? controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller?.sortingRoomsNotifier ?? ValueNotifier(false),
      builder: (context, sorting, child) {
        if (!sorting) return const SizedBox();

        return child ?? const SizedBox();
      },
      child: Container(
        height: 36,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator.adaptive(
              strokeWidth: 2,
              constraints: BoxConstraints(minHeight: 24, minWidth: 24),
            ),
            const SizedBox(width: 12),
            Text(
              L10n.of(context)!.synchronizingPleaseWait,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
