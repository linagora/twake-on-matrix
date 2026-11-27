import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

/// Someone who read a message: a name, and a picture when there is one.
typedef SeenReader = ({String name, Uri? avatar});

/// Who read an own message, under it: their small stacked avatars, or « Seen
/// by A, B ». The ticks are drawn by the time of the bubble, not here.
class SeenReaders extends StatelessWidget {
  const SeenReaders({super.key, required this.style, required this.readers});

  final SeenStyle style;
  final List<SeenReader> readers;

  static const double avatarSize = 16;
  static const int _maxAvatars = 4;

  @override
  Widget build(BuildContext context) {
    if (readers.isEmpty || style == SeenStyle.ticks) {
      return const SizedBox.shrink();
    }
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    if (style == SeenStyle.names) {
      return Text(_names(L10n.of(context)!), style: textStyle);
    }
    final shown = readers.take(_maxAvatars).toList();
    final more = readers.length - shown.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        SizedBox(
          width: avatarSize + (shown.length - 1) * avatarSize * 0.6,
          height: avatarSize,
          child: Stack(
            children: [
              for (final (index, reader) in shown.indexed)
                Positioned(
                  left: index * avatarSize * 0.6,
                  child: Tooltip(
                    message: reader.name,
                    child: _ReaderAvatar(reader: reader),
                  ),
                ),
            ],
          ),
        ),
        if (more > 0) Text('+$more', style: textStyle),
      ],
    );
  }

  String _names(L10n l10n) => switch (readers) {
    [final one] => l10n.seenByUser(one.name),
    [final one, final two] => l10n.seenByUserAndUser(one.name, two.name),
    [final one, ...final others] => l10n.seenByUserAndCountOthers(
      one.name,
      others.length,
    ),
    [] => '',
  };
}

class _ReaderAvatar extends StatelessWidget {
  const _ReaderAvatar({required this.reader});

  final SeenReader reader;

  @override
  Widget build(BuildContext context) {
    final avatar = reader.avatar;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.surface),
      ),
      child: avatar == null
          ? RoundAvatar(
              size: SeenReaders.avatarSize,
              text: reader.name.characters.first.toUpperCase(),
            )
          : Avatar(
              mxContent: avatar,
              name: reader.name,
              size: SeenReaders.avatarSize,
            ),
    );
  }
}
