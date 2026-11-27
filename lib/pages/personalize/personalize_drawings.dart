import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/domain/personalization/room_sections.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/personalize/personalize_choices.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';
import 'package:twake_chat/widgets/option_cards/option_cards.dart';

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
  const _MiniRoomList({required this.compact, required this.sections});

  final bool compact;
  final bool sections;

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
      child: ClipRect(
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
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w600,
        color: scheme.primary,
      ),
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
