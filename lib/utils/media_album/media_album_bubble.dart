import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.provider.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:twake_chat/pages/chat/events/images_builder/image_bubble.dart';
import 'package:twake_chat/pages/chat/events/message_content_style.dart';
import 'package:twake_chat/utils/extension/build_context_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/platform_infos.dart';

/// Grid of the images of one send: rows of two, an odd last row is full width.
class MediaAlbumBubble extends StatelessWidget {
  final List<Event> members;
  final bool isPreviewEnabled;
  final void Function() onTapSelectMode;

  const MediaAlbumBubble({
    super.key,
    required this.members,
    required this.isPreviewEnabled,
    required this.onTapSelectMode,
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
    final rows = <List<Event>>[
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

  Widget _tile(Event event, {required double width, required double height}) {
    return SizedBox(
      key: ValueKey('album-tile-${event.transactionId ?? event.eventId}'),
      width: width,
      height: height,
      child: !event.status.isSent
          ? _PendingTile(event: event)
          : ImageBubble(
              event,
              maxSize: false,
              rounded: false,
              width: width,
              height: height,
              fit: BoxFit.cover,
              animated: true,
              onTapPreview: isPreviewEnabled ? () {} : null,
              onTapSelectMode: onTapSelectMode,
            ),
    );
  }
}

/// An image that is still uploading: shows the local picture with a spinner
/// on top. A failed image leaves the album (see `GroupMediaEventsPolicy`) and
/// gets the retry of a single image bubble.
class _PendingTile extends ConsumerStatefulWidget {
  final Event event;

  const _PendingTile({required this.event});

  @override
  ConsumerState<_PendingTile> createState() => _PendingTileState();
}

class _PendingTileState extends ConsumerState<_PendingTile> {
  late Future<MatrixFile?> _file;

  @override
  void initState() {
    super.initState();
    _file = widget.event.getPlaceholderMatrixFile(
      ref.read(uploadManagerProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.event.filename,
      image: true,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          BlurHash(
            hash: widget.event.blurHash ?? MessageContentStyle.defaultBlurHash,
          ),
          FutureBuilder<MatrixFile?>(
            future: _file,
            builder: (context, snapshot) {
              final bytes = snapshot.data?.bytes;
              if (bytes == null || bytes.isEmpty) {
                return const SizedBox.shrink();
              }
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                cacheWidth: context.getCacheSize(256),
                filterQuality: FilterQuality.none,
              );
            },
          ),
          ColoredBox(color: Colors.black.withAlpha(40)),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
