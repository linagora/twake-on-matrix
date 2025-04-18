import 'package:fluffychat/config/themes.dart';
import 'package:flutter/material.dart';

import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/app_emojis.dart';

typedef OnSendEmojiReactionAction = void Function(
  String emoji,
  Event event,
);

typedef OnRemoveEmojiReactionAction = void Function(
  String emoji,
  Event event,
);

typedef OnPickEmojiReactionAction = void Function();

class ReactionsPicker extends StatelessWidget {
  final Event selectedEvent;
  final Timeline timeline;
  final OnSendEmojiReactionAction? onSendEmojiReaction;
  final OnPickEmojiReactionAction? onPickEmojiReaction;
  final Color? backgroundColor;

  const ReactionsPicker({
    super.key,
    required this.selectedEvent,
    required this.timeline,
    this.onSendEmojiReaction,
    this.onPickEmojiReaction,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: TwakeThemes.animationDuration,
      curve: TwakeThemes.animationCurve,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: Builder(
          builder: (context) {
            final emojis = List<String>.from(AppEmojis.emojisDefault);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor ??
                        LinagoraSysColors.material().onPrimary,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppConfig.borderRadius),
                    ),
                  ),
                  child: Row(
                    children: emojis.map((emoji) {
                      final myReaction = selectedEvent
                          .aggregatedEvents(
                            timeline,
                            RelationshipTypes.reaction,
                          )
                          .where(
                            (event) =>
                                event.senderId == event.room.client.userID &&
                                event.type == 'm.reaction',
                          )
                          .firstOrNull;
                      final relatesTo = (myReaction?.content
                          as Map<String, dynamic>?)?['m.relates_to'];
                      final isSelected = emoji == (relatesTo?['key'] ?? '');
                      return InkWell(
                        onTap: () async {
                          if (myReaction == null) {
                            onSendEmojiReaction?.call(emoji, selectedEvent);
                            return;
                          }

                          if (isSelected) {
                            Navigator.of(context).pop();
                            await myReaction.redactEvent();
                            return;
                          }

                          if (!isSelected) {
                            await myReaction.redactEvent();
                            onSendEmojiReaction?.call(emoji, selectedEvent);
                            return;
                          }
                        },
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        child: Container(
                          height: 56,
                          width: 56,
                          alignment: Alignment.center,
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: LinagoraSysColors.material()
                                      .onSurface
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                )
                              : null,
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 30),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                /// TODO: Implement the emoji picker later
                // InkWell(
                //   borderRadius: BorderRadius.circular(8),
                //   child: Container(
                //     margin: const EdgeInsets.symmetric(horizontal: 8),
                //     width: 56,
                //     height: 56,
                //     decoration: BoxDecoration(
                //       color: LinagoraSysColors.material().onPrimary,
                //       shape: BoxShape.circle,
                //     ),
                //     child: const Icon(Icons.add_outlined),
                //   ),
                //   onTap: () => onPickEmojiReaction?.call(),
                // ),
              ],
            );
          },
        ),
      ),
    );
  }
}
