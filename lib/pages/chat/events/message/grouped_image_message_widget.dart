import 'package:fluffychat/presentation/mixins/grouped_events_mixin.dart';
import 'package:fluffychat/pages/chat/events/images_builder/message_content_image_builder.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class GroupedImageMessageWidget extends StatelessWidget {
  final GroupedEvents groupedEvents;
  final void Function(Event)? onTapPreview;
  final void Function()? onTapSelectMode;

  static const double _imageSpacing = 2.0;

  const GroupedImageMessageWidget({
    super.key,
    required this.groupedEvents,
    this.onTapPreview,
    this.onTapSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    final images = groupedEvents.allEvents;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: switch (images.length) {
        1 => _buildSingleImage(images.first),
        2 => _buildTwoImages(images),
        3 => _buildThreeImages(images),
        4 => _buildFourImages(images),
        _ => _buildFiveOrMoreImages(images),
      },
    );
  }

  Widget _buildSingleImage(Event image) {
    return MessageImageBuilder(
      event: image,
      onTapPreview: () => onTapPreview?.call(image),
      onTapSelectMode: onTapSelectMode,
      rounded: false,
    );
  }

  Widget _buildTwoImages(List<Event> images) {
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: MessageImageBuilder(
              event: images[0],
              onTapPreview: () => onTapPreview?.call(images[0]),
              onTapSelectMode: onTapSelectMode,
              rounded: false,
            ),
          ),
        ),
        const SizedBox(width: _imageSpacing),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: MessageImageBuilder(
              event: images[1],
              onTapPreview: () => onTapPreview?.call(images[1]),
              onTapSelectMode: onTapSelectMode,
              rounded: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreeImages(List<Event> images) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: AspectRatio(
            aspectRatio: 1,
            child: MessageImageBuilder(
              event: images[0],
              onTapPreview: () => onTapPreview?.call(images[0]),
              onTapSelectMode: onTapSelectMode,
              rounded: false,
            ),
          ),
        ),
        const SizedBox(width: _imageSpacing),
        Expanded(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: MessageImageBuilder(
                  event: images[1],
                  onTapPreview: () => onTapPreview?.call(images[1]),
                  onTapSelectMode: onTapSelectMode,
                  rounded: false,
                ),
              ),
              const SizedBox(height: _imageSpacing),
              AspectRatio(
                aspectRatio: 1,
                child: MessageImageBuilder(
                  event: images[2],
                  onTapPreview: () => onTapPreview?.call(images[2]),
                  onTapSelectMode: onTapSelectMode,
                  rounded: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFourImages(List<Event> images) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: MessageImageBuilder(
                  event: images[0],
                  onTapPreview: () => onTapPreview?.call(images[0]),
                  onTapSelectMode: onTapSelectMode,
                  rounded: false,
                ),
              ),
            ),
            const SizedBox(width: _imageSpacing),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: MessageImageBuilder(
                  event: images[1],
                  onTapPreview: () => onTapPreview?.call(images[1]),
                  onTapSelectMode: onTapSelectMode,
                  rounded: false,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _imageSpacing),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: MessageImageBuilder(
                  event: images[2],
                  onTapPreview: () => onTapPreview?.call(images[2]),
                  onTapSelectMode: onTapSelectMode,
                  rounded: false,
                ),
              ),
            ),
            const SizedBox(width: _imageSpacing),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: MessageImageBuilder(
                  event: images[3],
                  onTapPreview: () => onTapPreview?.call(images[3]),
                  onTapSelectMode: onTapSelectMode,
                  rounded: false,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiveOrMoreImages(List<Event> images) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: MessageImageBuilder(
                  event: images[0],
                  onTapPreview: () => onTapPreview?.call(images[0]),
                  onTapSelectMode: onTapSelectMode,
                  rounded: false,
                ),
              ),
            ),
            const SizedBox(width: _imageSpacing),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: MessageImageBuilder(
                  event: images[1],
                  onTapPreview: () => onTapPreview?.call(images[1]),
                  onTapSelectMode: onTapSelectMode,
                  rounded: false,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _imageSpacing),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: MessageImageBuilder(
                  event: images[2],
                  onTapPreview: () => onTapPreview?.call(images[2]),
                  onTapSelectMode: onTapSelectMode,
                  rounded: false,
                ),
              ),
            ),
            const SizedBox(width: _imageSpacing),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MessageImageBuilder(
                      event: images[3],
                      onTapPreview: () => onTapPreview?.call(images[3]),
                      onTapSelectMode: onTapSelectMode,
                      rounded: false,
                    ),
                    if (images.length > 4)
                      Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: Text(
                            '+${images.length - 4}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
