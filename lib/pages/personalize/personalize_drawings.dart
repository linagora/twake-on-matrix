import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/domain/personalization/room_sections.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/seen_readers.dart';
import 'package:twake_chat/pages/personalize/personalize_choices.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_search_style.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';
import 'package:twake_chat/widgets/option_cards/option_cards.dart';

part 'personalize_step_body.dart';
part 'personalize_step_cards.dart';

/// The sections the previews show, in the order of the chat list.
final List<RoomSectionKind> _previewSections = [
  for (final kind in roomSectionOrder)
    if (kind != RoomSectionKind.spaces) kind,
];

String _sectionTitle(L10n l10n, RoomSectionKind kind) => switch (kind) {
  RoomSectionKind.unread => l10n.unread,
  RoomSectionKind.spaces => l10n.roomSectionSpaces,
  RoomSectionKind.groups => l10n.groups,
  RoomSectionKind.directs => l10n.directChats,
};

// The drawn previews of the personalization choices, shared by the settings
// cards and the start flow. Made-up data only.

/// A drawn room list: an avatar and two lines per room, under section titles
/// in the order « sections ».
class _MiniRoomList extends StatelessWidget {
  const _MiniRoomList({
    required this.compact,
    required this.sections,
    this.search,
  });

  final bool compact;
  final bool sections;

  /// Where the search is drawn: none when null.
  final ChatListSearchStyle? search;

  static const double _width = 120;

  static const double _height = 180;

  /// The rooms drawn under the title of a section.
  static int _roomsOf(RoomSectionKind kind) =>
      kind == RoomSectionKind.directs ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = L10n.of(context)!;
    final row = _MiniRoom(compact: compact, scheme: scheme);
    final rows = compact ? 7 : 5;
    return Container(
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: _WithSearch(
        style: search,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections
                  ? [
                      for (final kind in _previewSections) ...[
                        _MiniTitle(_sectionTitle(l10n, kind), scheme: scheme),
                        for (var i = 0; i < _roomsOf(kind); i++) row,
                      ],
                    ]
                  : [for (var i = 0; i < rows; i++) row],
            ),
          ),
        ),
      ),
    );
  }
}

/// [child] (the rooms) with a drawn search above it (collapsing) or below it
/// (bottom bar); alone when [style] is null.
class _WithSearch extends StatelessWidget {
  const _WithSearch({required this.style, required this.child});

  final ChatListSearchStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    if (style == null) return child;
    final scheme = Theme.of(context).colorScheme;
    final search = switch (style) {
      ChatListSearchStyle.bottomBar => Align(
        alignment: Alignment.centerRight,
        child: Icon(Icons.search, size: 16, color: scheme.primary),
      ),
      ChatListSearchStyle.collapsing => Container(
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(9)),
        ),
        child: Icon(Icons.search, size: 12, color: scheme.onSurfaceVariant),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        if (style == ChatListSearchStyle.collapsing) search,
        Expanded(child: child),
        if (style == ChatListSearchStyle.bottomBar) search,
      ],
    );
  }
}

class _MiniTitle extends StatelessWidget {
  const _MiniTitle(this.text, {required this.scheme});

  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textScaler: TextScaler.noScaling,
      style: LinagoraTextStyle.material().bodySmall
          .apply(fontSizeFactor: 2 / 3)
          .copyWith(fontWeight: FontWeight.w600, color: scheme.primary),
    ),
  );
}

class _MiniRoom extends StatelessWidget {
  const _MiniRoom({required this.compact, required this.scheme});

  final bool compact;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final avatar = compact ? 12.0 : 18.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 3 : 6),
      child: Row(
        spacing: 6,
        children: [
          Container(
            width: avatar,
            height: avatar,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                _Bar(widthFactor: 0.7, color: scheme.onSurface),
                _Bar(widthFactor: 0.9, color: scheme.outlineVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.widthFactor, required this.color});

  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
    ),
  );
}

/// A drawn bubble, on the right when [end].
class _MiniBubble extends StatelessWidget {
  const _MiniBubble({required this.own, required this.end, this.trailing});

  final bool own;
  final bool end;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: end ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: own ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          spacing: 6,
          children: [
            Expanded(
              child: _Bar(widthFactor: 1, color: scheme.onSurfaceVariant),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _MiniBubbles extends StatelessWidget {
  const _MiniBubbles({required this.ownRight});

  final bool ownRight;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    child: Column(
      spacing: 6,
      children: [
        const _MiniBubble(own: false, end: false),
        _MiniBubble(own: true, end: ownRight),
      ],
    ),
  );
}

/// An own message read by Alice, Bruno and Chloé, in [style].
class _MiniSeen extends StatelessWidget {
  const _MiniSeen({required this.style});

  final SeenStyle style;

  static const List<SeenReader> _readers = [
    (name: 'Alice', avatar: null),
    (name: 'Bruno', avatar: null),
    (name: 'Chloé', avatar: null),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 4,
      children: [
        _MiniBubble(
          own: true,
          end: true,
          trailing: Icon(
            Icons.done_all,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SeenReaders(style: style, readers: _readers),
      ],
    ),
  );
}

/// A drawn message field: tools under the text (compact) or around it.
class _MiniComposer extends StatelessWidget {
  const _MiniComposer({required this.style});

  final ComposerStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hint = Text(
      L10n.of(context)!.message,
      textScaler: TextScaler.noScaling,
      style: LinagoraTextStyle.material().bodySmall.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
    final border = BoxDecoration(
      color: scheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      border: Border.all(color: scheme.outline),
    );
    Widget tool(IconData icon) =>
        Icon(icon, size: 16, color: scheme.onSurfaceVariant);
    final send = Icon(Icons.send, size: 16, color: scheme.primary);
    if (style == ComposerStyle.compact) {
      return Container(
        width: 280,
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 6),
        decoration: border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            hint,
            Row(
              spacing: 8,
              children: [
                tool(Icons.add_circle_outline),
                tool(Icons.tag_faces),
                const Spacer(),
                send,
              ],
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: 280,
      child: Row(
        spacing: 6,
        children: [
          tool(Icons.add_circle_outline),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: border,
              child: Row(
                children: [
                  Expanded(child: hint),
                  tool(Icons.tag_faces),
                ],
              ),
            ),
          ),
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.primary,
            child: Icon(Icons.send, size: 14, color: scheme.onPrimary),
          ),
        ],
      ),
    );
  }
}
