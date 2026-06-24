import 'package:equatable/equatable.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/events/message_reactions_bottom_sheet.dart';
import 'package:fluffychat/pages/chat/events/message_reactions_style.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:overflow_view/overflow_view.dart';

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
    return OverflowView.flexible(
      spacing: 4.0,
      builder: (context, index) {
        if (event.room.isDirectChat) {
          return const SizedBox.shrink();
        }
        return InkWell(
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTapDown: (details) {
            _handleDisplayReactionsInfo(
              context: context,
              tapDownDetails: details,
            );
          },
          child: Container(
            width: MessageReactionsStyle.moreReactionContainer,
            height: MessageReactionsStyle.moreReactionContainer,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: MessageReactionsStyle.borderColor),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.more_horiz_rounded,
                size: MessageReactionsStyle.moreReactionIconSize,
              ),
            ),
          ),
        );
      },
      children: [
        ...reactionList
            .take(3)
            .map(
              (r) => Reaction(
                reactionKey: r.key,
                count: event.room.isDirectChat ? null : r.count,
                reacted: r.reacted,
                onTap: () async {
                  if (r.reacted) {
                    final evt = allReactionEvents.firstWhereOrNull((e) {
                      final relatedTo = e.content['m.relates_to'];
                      return e.senderId == e.room.client.userID &&
                          relatedTo is Map &&
                          relatedTo['key'] == r.key;
                    });
                    if (evt != null) {
                      await evt.redactEvent();
                    }
                  } else {
                    event.room.sendReaction(event.eventId, r.key!);
                  }
                },
              ),
            ),
        if (reactionList.length > 3)
          Container(
            width: MessageReactionsStyle.moreReactionContainer,
            height: MessageReactionsStyle.moreReactionContainer,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: MessageReactionsStyle.borderColor),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: Center(
              child: Text(
                '+${reactionList.length - 3}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LinagoraRefColors.material().neutral[50],
                ),
              ),
            ),
          ),
        if (!event.room.isDirectChat && reactionList.isNotEmpty)
          InkWell(
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTapDown: (details) {
              _handleDisplayReactionsInfo(
                context: context,
                tapDownDetails: details,
              );
            },
            child: Container(
              width: MessageReactionsStyle.moreReactionContainer,
              height: MessageReactionsStyle.moreReactionContainer,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: MessageReactionsStyle.borderColor),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: MessageReactionsStyle.moreReactionIconSize,
                ),
              ),
            ),
          ),
      ],
    );
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: MessageReactionsBottomSheet(
                          event: event,
                          allReactionEvents: allReactionEvents,
                          client: client,
                          reactionList: reactionList,
                          scrollController: ScrollController(),
                          reactionHeaderPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          reactionListPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
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
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
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
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    width: 32,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: LinagoraSysColors.material().outline,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  Expanded(
                    child: MessageReactionsBottomSheet(
                      event: event,
                      allReactionEvents: allReactionEvents,
                      client: client,
                      reactionList: reactionList,
                      scrollController: scrollController,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class Reaction extends StatelessWidget {
  final String? reactionKey;
  final int? count;
  final bool? reacted;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final bool enableDecoration;
  final TextStyle? countStyle;

  const Reaction({
    super.key,
    this.reactionKey,
    this.count,
    this.reacted,
    this.onTap,
    this.onLongPress,
    this.enableDecoration = true,
    this.countStyle,
  });

  @override
  Widget build(BuildContext context) {
    final color = LinagoraSysColors.material().surface;
    final fontSize = DefaultTextStyle.of(context).style.fontSize;
    Widget content;
    if (reactionKey!.startsWith('mxc://')) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MxcImage(uri: Uri.parse(reactionKey!), width: 9999, height: fontSize),
          if (count != null && count! > 1) ...[
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LinagoraRefColors.material().neutral[50],
              ),
            ),
          ],
        ],
      );
    } else {
      final renderKey = Characters(reactionKey!);
      content = Text(
        '$renderKey',
        strutStyle: const StrutStyle(forceStrutHeight: true),
        style: TextStyle(fontSize: MessageReactionsStyle.renderKeyFontSize),
        textAlign: TextAlign.center,
      );
    }
    return InkWell(
      onTap: () => onTap != null ? onTap!() : null,
      onLongPress: () => onLongPress != null ? onLongPress!() : null,
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      child: Container(
        height: 28,
        decoration: enableDecoration
            ? BoxDecoration(
                color: color,
                border: Border.all(
                  color: MessageReactionsStyle.reactionBorderColor,
                ),
                borderRadius: BorderRadius.circular(
                  MessageReactionsStyle.reactionBorderRadius,
                ),
              )
            : null,
        padding: const EdgeInsets.only(left: 4, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.only(top: 4), child: content),
            if (count != null && count! > 1) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style:
                    countStyle ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LinagoraRefColors.material().neutral[50],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
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
