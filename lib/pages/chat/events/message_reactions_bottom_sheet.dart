import 'package:twake_chat/pages/chat/events/message_reactions.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

class MessageReactionsBottomSheet extends StatefulWidget {
  final List<ReactionEntry> reactionList;
  final Set<Event> allReactionEvents;
  final ScrollController scrollController;

  const MessageReactionsBottomSheet({
    super.key,
    required this.reactionList,
    required this.allReactionEvents,
    required this.scrollController,
  });

  @override
  State<MessageReactionsBottomSheet> createState() =>
      _MessageReactionsBottomSheetState();
}

class _MessageReactionsBottomSheetState
    extends State<MessageReactionsBottomSheet> {
  // 0 is the "All" tab, then one tab per reaction.
  int _selectedIndex = 0;

  List<ReactionEntry> get _displayedReactions => _selectedIndex == 0
      ? widget.reactionList
      : [widget.reactionList[_selectedIndex - 1]];

  LinagoraReactionTab _tabFor(ReactionEntry reaction) {
    return reaction.isCustomEmoji
        ? LinagoraReactionTab(
            label: '${reaction.count}',
            image: reaction.customEmojiImage,
          )
        : LinagoraReactionTab(label: '${reaction.key} ${reaction.count}');
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final reaction in _displayedReactions)
        for (final reactor in reaction.reactors ?? <User>[])
          _ReactorItem(reaction: reaction, reactor: reactor),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinagoraReactionTabs(
          tabs: [
            LinagoraReactionTab(
              label:
                  '${L10n.of(context)!.all} ${widget.allReactionEvents.length}',
            ),
            ...widget.reactionList.map(_tabFor),
          ],
          selectedIndex: _selectedIndex,
          onSelected: (index) => setState(() => _selectedIndex = index),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }
}

class _ReactorItem extends StatelessWidget {
  static const _size = LinagoraReactionItemSize.large;

  final ReactionEntry reaction;
  final User reactor;

  const _ReactorItem({required this.reaction, required this.reactor});

  @override
  Widget build(BuildContext context) {
    final name = reactor.displayName ?? '';
    final avatar = Avatar(
      size: _size.avatarSize,
      mxContent: reactor.avatarUrl,
      name: reactor.displayName,
    );
    return reaction.isCustomEmoji
        ? LinagoraReactionItem.image(
            name: name,
            image: reaction.customEmojiImage,
            avatar: avatar,
            size: _size,
          )
        : LinagoraReactionItem(
            name: name,
            emoji: reaction.key!,
            avatar: avatar,
            size: _size,
          );
  }
}
