import 'package:fluffychat/config/themes.dart';
import 'package:flutter/material.dart';

import 'package:emoji_proposal/emoji_proposal.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/app_emojis.dart';

typedef OnSendEmojiReactionAction = void Function(
  String emoji,
  Event event,
);

typedef OnPickEmojiReactionAction = void Function();

class ReactionsPicker extends StatelessWidget {
  final Event selectedEvent;
  final Timeline timeline;
  final OnSendEmojiReactionAction? onSendEmojiReaction;
  final OnPickEmojiReactionAction? onPickEmojiReaction;

  const ReactionsPicker({
    super.key,
    required this.selectedEvent,
    required this.timeline,
    this.onSendEmojiReaction,
    this.onPickEmojiReaction,
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
            final proposals = proposeEmojis(
              selectedEvent.plaintextBody,
              number: 25,
              languageCodes: EmojiProposalLanguageCodes.values.toSet(),
            );
            final emojis = proposals.isNotEmpty
                ? proposals.map((e) => e.char).toList()
                : List<String>.from(AppEmojis.emojis);
            final allReactionEvents = selectedEvent
                .aggregatedEvents(
                  timeline,
                  RelationshipTypes.reaction,
                )
                .where(
                  (event) =>
                      event.senderId == event.room.client.userID &&
                      event.type == 'm.reaction',
                );

            for (final event in allReactionEvents) {
              try {
                final relateTo = event.content['m.relates_to'];
                if (relateTo == null || relateTo is! Map) {
                  continue;
                }
                emojis.remove(relateTo['key']);
              } catch (_) {}
            }
            return Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: LinagoraSysColors.material().onPrimary,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppConfig.borderRadius),
                      ),
                    ),
                    padding: const EdgeInsets.only(right: 1),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: emojis.length,
                      itemBuilder: (c, i) => InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onSendEmojiReaction?.call(
                          emojis[i],
                          selectedEvent,
                        ),
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          child: Text(
                            emojis[i],
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: LinagoraSysColors.material().onPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_outlined),
                  ),
                  onTap: () => onPickEmojiReaction?.call(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
