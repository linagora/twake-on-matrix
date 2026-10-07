import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/pages/chat/events/message_reactions_bottom_sheet.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/reaction/linagora_reaction_chip.dart';
import 'package:linagora_design_flutter/reaction/linagora_reactions.dart';
import 'package:matrix/matrix.dart';

import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/mxc_image.dart';

class MessageReactions extends StatelessWidget {
  final Event event;
  final Timeline timeline;

  const MessageReactions(this.event, this.timeline, {super.key});

  @override
  Widget build(BuildContext context) {
    final allReactionEvents = event.aggregatedEvents(
      timeline,
      RelationshipTypes.reaction,
    );
    final reactionMap = <String, ReactionEntry>{};
    final client = Matrix.of(context).client;

    for (final e in allReactionEvents) {
      final key = e.content
          .tryGetMap<String, dynamic>('m.relates_to')
          ?.tryGet<String>('key');
      if (key != null) {
        if (!reactionMap.containsKey(key)) {
          reactionMap[key] = ReactionEntry(
            key: key,
            count: 0,
            reacted: false,
            reactors: [],
          );
        }
        reactionMap[key]!.count++;
        reactionMap[key]!.reactors!.add(e.senderFromMemoryOrFallback);
        reactionMap[key]!.reacted |= e.senderId == e.room.client.userID;
      }
    }

    final reactionList = reactionMap.values.toList();
    reactionList.sort((a, b) => b.count - a.count > 0 ? 1 : -1);
    return Material(
      color: Colors.transparent,
      child: ReactionsList(
        reactionList: reactionList,
        allReactionEvents: allReactionEvents,
        event: event,
        client: client,
      ),
    );
  }
}

class ReactionsList extends StatelessWidget {
  const ReactionsList({
    super.key,
    required this.reactionList,
    required this.allReactionEvents,
    required this.event,
    required this.client,
  });

  final List<ReactionEntry> reactionList;
  final Set<Event> allReactionEvents;
  final Event event;
  final Client client;

  @override
  Widget build(BuildContext context) {
    final isDirectChat = event.room.isDirectChat;
    return LinagoraReactions(
      reactions: reactionList.map((r) {
        final count = isDirectChat ? null : r.count;
        void onTap() => unawaited(_toggleReaction(r));
        return r.isCustomEmoji
            ? LinagoraReactionChip.image(
                image: r.customEmojiImage,
                count: count,
                onTap: onTap,
              )
            : LinagoraReactionChip(emoji: r.key!, count: count, onTap: onTap);
      }).toList(),
      onShowAll: isDirectChat
          ? null
          : (details) => _handleDisplayReactionsInfo(
              context: context,
              tapDownDetails: details,
            ),
    );
  }

  Future<void> _toggleReaction(ReactionEntry reaction) async {
    if (!reaction.reacted) {
      await event.room.sendReaction(event.eventId, reaction.key!);
      return;
    }
    final ownReaction = allReactionEvents.firstWhereOrNull((e) {
      final relatedTo = e.content['m.relates_to'];
      return e.senderId == e.room.client.userID &&
          relatedTo is Map &&
          relatedTo['key'] == reaction.key;
    });
    await ownReaction?.redactEvent();
  }

  void _handleDisplayReactionInfoWeb({
    required BuildContext context,
    required TapDownDetails tapDownDetails,
  }) {
    final offset = tapDownDetails.globalPosition;
    final double positionLeftTap = offset.dx;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double availableRightSpace = screenWidth - positionLeftTap;
    final double positionBottomTap = offset.dy;
    final double heightScreen = MediaQuery.sizeOf(context).height;
    final double availableBottomSpace = heightScreen - positionBottomTap;
    double? positionLeft;
    double? positionRight;
    double? positionTop;
    double? positionBottom;
    Alignment alignment = Alignment.topLeft;

    if (availableRightSpace < AppConfig.defaultMaxWidthReactionsView) {
      positionRight = screenWidth - positionLeftTap;
      alignment = Alignment.topRight;
    } else {
      positionLeft = positionLeftTap;
    }

    if (availableBottomSpace < AppConfig.defaultMaxHeightReactionsView) {
      positionBottom = availableBottomSpace;
    } else {
      positionTop = positionBottomTap;
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (dialogContext) => GestureDetector(
        onTap: Navigator.of(dialogContext).pop,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            height: 56,
            width: double.infinity,
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  left: positionLeft,
                  top: positionTop,
                  bottom: positionBottom,
                  right: positionRight,
                  child: Align(
                    alignment: alignment,
                    child: Container(
                      width: AppConfig.defaultMaxWidthReactionsView,
                      height: AppConfig.defaultMaxHeightReactionsView,
                      decoration: BoxDecoration(
                        color: LinagoraRefColors.material().primary[100],
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0000004D).withOpacity(0.15),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: const Color(0x00000026).withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: MessageReactionsBottomSheet(
                          allReactionEvents: allReactionEvents,
                          reactionList: reactionList,
                          scrollController: ScrollController(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleDisplayReactionsInfo({
    required BuildContext context,
    required TapDownDetails tapDownDetails,
  }) async {
    final responsive = getIt.get<ResponsiveUtils>();
    if (!responsive.isMobile(context)) {
      _handleDisplayReactionInfoWeb(
        context: context,
        tapDownDetails: tapDownDetails,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        width: double.infinity,
        padding: MediaQuery.viewInsetsOf(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.8,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Column(
              children: [
                Container(
                  height: 4,
                  width: 32,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: LinagoraSysColors.material().outline.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                Expanded(
                  child: MessageReactionsBottomSheet(
                    allReactionEvents: allReactionEvents,
                    reactionList: reactionList,
                    scrollController: scrollController,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ReactionEntry with EquatableMixin {
  String? key;
  int count;
  bool reacted;
  List<User>? reactors;

  ReactionEntry({
    this.key,
    required this.count,
    required this.reacted,
    this.reactors,
  });

  @override
  List<Object?> get props => [key, count, reacted, reactors];
}

extension ReactionEntryCustomEmoji on ReactionEntry {
  bool get isCustomEmoji => key!.startsWith('mxc://');

  Widget get customEmojiImage =>
      MxcImage(uri: Uri.parse(key!), fit: BoxFit.contain);
}
