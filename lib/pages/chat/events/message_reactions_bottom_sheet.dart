import 'package:fluffychat/pages/chat/events/message_reactions.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class MessageReactionsBottomSheet extends StatefulWidget {
  final List<ReactionEntry> reactionList;
  final Set<Event> allReactionEvents;
  final Event event;
  final Client client;
  final ScrollController scrollController;
  final EdgeInsets? reactionListPadding;
  final EdgeInsets? reactionHeaderPadding;

  const MessageReactionsBottomSheet({
    super.key,
    required this.reactionList,
    required this.allReactionEvents,
    required this.event,
    required this.client,
    required this.scrollController,
    this.reactionListPadding,
    this.reactionHeaderPadding,
  });

  @override
  State<MessageReactionsBottomSheet> createState() =>
      _MessageReactionsBottomSheetState();
}

class _MessageReactionsBottomSheetState
    extends State<MessageReactionsBottomSheet> {
  final ValueNotifier<List<ReactionEntry>> _reactionListNotifier =
      ValueNotifier<List<ReactionEntry>>([]);

  final ValueNotifier<String?> _selectedReactionKeyNotifier =
      ValueNotifier<String?>(null);

  void onSelectedReaction(String? reactionKey) {
    final reactionList = widget.reactionList
        .where((reaction) => reaction.key == reactionKey)
        .toList();

    _reactionListNotifier.value = reactionList;
    _selectedReactionKeyNotifier.value = reactionKey;
  }

  void onSelectedAllReaction() {
    _reactionListNotifier.value = widget.reactionList;
    _selectedReactionKeyNotifier.value = null;
  }

  @override
  void initState() {
    onSelectedAllReaction();
    super.initState();
  }

  @override
  void dispose() {
    _reactionListNotifier.dispose();
    _selectedReactionKeyNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            width: double.infinity,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: widget.reactionHeaderPadding,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      onSelectedAllReaction();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 24,
                            child: Text(
                              "${L10n.of(context)!.all} ${widget.allReactionEvents.length}",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: LinagoraSysColors.material()
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                          ValueListenableBuilder(
                            valueListenable: _selectedReactionKeyNotifier,
                            builder: (context, selectedReactionKey, child) {
                              return Container(
                                height: 3,
                                width: 32,
                                margin: const EdgeInsets.only(top: 11),
                                decoration: selectedReactionKey == null
                                    ? BoxDecoration(
                                        color: LinagoraSysColors.material()
                                            .primary,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(100),
                                          topRight: Radius.circular(100),
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...widget.reactionList.map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 24,
                            child: Reaction(
                              reactionKey: r.key,
                              enableDecoration: false,
                              count: widget.event.room.isDirectChat
                                  ? null
                                  : r.count,
                              reacted: r.reacted,
                              onTap: () async {
                                onSelectedReaction(r.key);
                              },
                              countStyle: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: LinagoraSysColors.material()
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                          ValueListenableBuilder(
                            valueListenable: _selectedReactionKeyNotifier,
                            builder: (context, selectedReactionKey, child) {
                              return Container(
                                height: 3,
                                width: 32,
                                margin: const EdgeInsets.only(top: 11),
                                decoration: selectedReactionKey != null &&
                                        selectedReactionKey == r.key
                                    ? BoxDecoration(
                                        color: LinagoraSysColors.material()
                                            .primary,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(100),
                                          topRight: Radius.circular(100),
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder(
            valueListenable: _reactionListNotifier,
            builder: (_, reactionList, child) {
              return Expanded(
                child: ListView.builder(
                  controller: widget.scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: widget.reactionListPadding,
                  itemCount: reactionList.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: reactionList[index].reactors?.map((reactor) {
                            return Container(
                              height: 40,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Avatar(
                                    size: 24,
                                    mxContent: reactor.avatarUrl,
                                    name: reactor.displayName,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      reactor.displayName ?? "",
                                      style: LinagoraTextStyle.material()
                                          .bodyMedium2
                                          .copyWith(
                                            color: LinagoraSysColors.material()
                                                .onSurface,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Reaction(
                                    reactionKey: reactionList[index].key,
                                    enableDecoration: false,
                                    count: null,
                                    reacted: false,
                                  ),
                                ],
                              ),
                            );
                          }).toList() ??
                          [],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
