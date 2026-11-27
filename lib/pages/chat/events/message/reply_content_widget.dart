import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:twake_chat/pages/chat/events/reply_content.dart';
import 'package:twake_chat/pages/chat/events/reply_content_style.dart';
import 'package:twake_chat/pages/chat/optional_ink_well.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:linagora_design_flutter/chat/bubble_shape.dart';
import 'package:linagora_design_flutter/chat/bubble_with_reactions.dart';
import 'package:matrix/matrix.dart';

class ReplyContentWidget extends StatefulWidget {
  const ReplyContentWidget({
    super.key,
    required this.event,
    required this.timeline,
    required this.scrollToEventId,
    required this.alignment,
  });

  final Event event;
  final Timeline timeline;
  final void Function(String p1)? scrollToEventId;
  final CrossAxisAlignment alignment;

  @override
  State<ReplyContentWidget> createState() => _ReplyContentWidgetState();
}

class _ReplyContentWidgetState extends State<ReplyContentWidget> {
  /// The lookup of a quote the timeline does not hold: made once, as each one
  /// may ask the server.
  Future<Event?>? _lookup;
  String? _lookupId;
  Timeline? _lookupTimeline;

  @override
  Widget build(BuildContext context) {
    final quotedId = widget.event.inReplyToEventId();
    if (quotedId == null) return const SizedBox();

    // Read at once, so that a loaded quote shows from the first frame.
    final loaded = widget.timeline.events.firstWhereOrNull(
      (event) => event.eventId == quotedId,
    );
    if (loaded != null) return _quote(quotedId, loaded);

    if (_lookupId != quotedId || _lookupTimeline != widget.timeline) {
      _lookupId = quotedId;
      _lookupTimeline = widget.timeline;
      _lookup = null;
    }
    return FutureBuilder<Event?>(
      future: _lookup ??= widget.event.getReplyEvent(widget.timeline),
      builder: (context, snapshot) =>
          snapshot.connectionState == ConnectionState.done
          ? _quote(quotedId, snapshot.data)
          : const SizedBox(),
    );
  }

  /// [quoted] is null when the message cannot be found.
  Widget _quote(String quotedId, Event? quoted) {
    return OptionalInkWell(
      onTap: () => widget.scrollToEventId?.call(quotedId),
      isEnabled: widget.scrollToEventId != null,
      child: ReplyContent(
        quoted ??
            Event(
              eventId: quotedId,
              content: {'msgtype': 'm.text', 'body': '...'},
              senderId: widget.event.senderId,
              type: 'm.room.message',
              room: widget.event.room,
              status: EventStatus.sent,
              originServerTs: DateTime.now(),
            ),
        timeline: widget.timeline,
        quoteAlignment: widget.alignment,
        quoteOverlap: ReplyContentStyle.quoteOverlap,
        // The placeholder borrows the sender of the reply.
        quoteSenderUnknown: quoted == null,
      ),
    );
  }
}

/// A quote above its message bubble: the bubble covers the bottom of the quote,
/// parted from it by a gap. A [Column] has no negative spacing.
class ReplyColumn extends Column {
  const ReplyColumn({
    super.key,
    required super.crossAxisAlignment,
    required super.children,
  }) : super(
         mainAxisSize: MainAxisSize.min,
         // The side of the bubble is physical, in right-to-left languages too.
         textDirection: TextDirection.ltr,
       );

  @override
  RenderFlex createRenderObject(BuildContext context) =>
      _RenderReplyColumn(crossAxisAlignment: crossAxisAlignment);
}

class _RenderReplyColumn extends RenderFlex {
  _RenderReplyColumn({required super.crossAxisAlignment})
    : super(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
      );

  final _clip = LayerHandle<ClipPathLayer>();

  /// Nothing is covered while there is no quote.
  double _overlapOf(double quoteHeight) =>
      math.min(quoteHeight, ReplyContentStyle.quoteOverlap);

  Size _shorten(Size size, double quoteHeight) =>
      Size(size.width, size.height - _overlapOf(quoteHeight));

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) -
      _overlapOf(firstChild!.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) -
      _overlapOf(firstChild!.getMaxIntrinsicHeight(width));

  @override
  Size computeDryLayout(BoxConstraints constraints) => _shorten(
    super.computeDryLayout(constraints),
    firstChild!
        .getDryLayout(BoxConstraints(maxWidth: constraints.maxWidth))
        .height,
  );

  @override
  void performLayout() {
    super.performLayout();
    final quoteHeight = firstChild!.size.height;
    (lastChild!.parentData! as FlexParentData).offset -= Offset(
      0,
      _overlapOf(quoteHeight),
    );
    size = _shorten(size, quoteHeight);
  }

  /// The quote is clipped around the bubble rather than painted over by a ring
  /// of one colour: the row behind shows in the gap, with no offscreen layer.
  @override
  void paint(PaintingContext context, Offset offset) {
    final quote = firstChild!;
    final bubble = lastChild!;
    final quoteAt = (quote.parentData! as FlexParentData).offset;
    final bubbleAt = (bubble.parentData! as FlexParentData).offset;
    // With reactions wider than it, the bubble is only a part of its box.
    var shape = bubbleAt & bubble.size;
    if (bubble is RenderBubbleWithReactions) {
      final box = bubble.firstChild!;
      final boxAt = (box.parentData! as BoxParentData).offset;
      shape = (bubbleAt + boxAt) & box.size;
    }
    final gap = Path()
      ..addRRect(
        BubbleRadius.all.toRRect(
          shape.inflate(ReplyContentStyle.quoteRingWidth),
        ),
      );
    _clip.layer = context.pushClipPath(
      needsCompositing,
      offset,
      quoteAt & quote.size,
      Path.combine(
        PathOperation.difference,
        Path()..addRect(quoteAt & quote.size),
        gap,
      ),
      (context, offset) => context.paintChild(quote, offset + quoteAt),
      oldLayer: _clip.layer,
    );
    context.paintChild(bubble, offset + bubbleAt);
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}
