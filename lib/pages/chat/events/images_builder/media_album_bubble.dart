import 'dart:math';

import 'package:flutter/material.dart';
import 'package:twake_chat/pages/chat/events/images_builder/media_album_scope.dart';
import 'package:twake_chat/pages/chat/events/message_content_style.dart';
import 'package:twake_chat/utils/platform_infos.dart';

/// Builds the content of one tile of the album, sized [width] x [height].
typedef MediaAlbumTileBuilder<T> =
    Widget Function(
      BuildContext context,
      T member, {
      required double width,
      required double height,
    });

/// Grid of the images of one send: rows of two, an odd last row is full width.
///
/// Generic over the member type so that it does not depend on the Matrix
/// SDK: the caller gives the key and the content of each tile.
class MediaAlbumBubble<T> extends StatelessWidget {
  final List<T> members;
  final Object Function(T member) keyOf;
  final MediaAlbumTileBuilder<T> tileBuilder;

  const MediaAlbumBubble({
    super.key,
    required this.members,
    required this.keyOf,
    required this.tileBuilder,
  });

  static const double _gap = 2;

  /// Width of the grid, so that a caption below it lines up with it.
  static double widthFor() => PlatformInfos.isWeb
      ? MessageContentStyle.imageBubbleWidthForWeb * 0.8
      : MessageContentStyle.imageBubbleWidthForMobileAndTablet;

  @override
  Widget build(BuildContext context) {
    final bubbleWidth = widthFor();
    final tile = (bubbleWidth - _gap) / 2;
    final rows = <List<T>>[
      for (var i = 0; i < members.length; i += 2)
        members.sublist(i, min(i + 2, members.length)),
    ];
    return ClipRRect(
      borderRadius: MessageContentStyle.borderRadiusBubble,
      child: SizedBox(
        width: bubbleWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: _gap),
              Row(
                children: [
                  for (var c = 0; c < rows[r].length; c++) ...[
                    if (c > 0) const SizedBox(width: _gap),
                    _tile(
                      context,
                      rows[r][c],
                      width: rows[r].length == 1 ? bubbleWidth : tile,
                      height: tile,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    T member, {
    required double width,
    required double height,
  }) {
    return Listener(
      key: ValueKey('album-tile-${keyOf(member)}'),
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => MediaAlbumPressScope.report<T>(context, member),
      child: SizedBox(
        width: width,
        height: height,
        child: tileBuilder(context, member, width: width, height: height),
      ),
    );
  }
}
