import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';

class RecentChatsTitle extends StatelessWidget {
  const RecentChatsTitle({
    super.key,
    required this.isShowRecentlyChats,
    required this.toggleRecentChat,
  });

  final bool isShowRecentlyChats;

  final void Function() toggleRecentChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          L10n.of(context)!.recentlyChats,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TwakeIconButton(
                paddingAll: 6.0,
                buttonDecoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                icon:
                    isShowRecentlyChats ? Icons.expand_less : Icons.expand_more,
                onTap: toggleRecentChat,
                tooltip: isShowRecentlyChats
                    ? L10n.of(context)!.shrink
                    : L10n.of(context)!.expand,
              ),
            ],
          ),
        )
      ],
    );
  }
}
