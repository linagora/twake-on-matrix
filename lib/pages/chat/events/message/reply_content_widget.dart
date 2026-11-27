import 'package:twake_chat/pages/chat/events/reply_content.dart';
import 'package:twake_chat/pages/chat/optional_ink_well.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:matrix/matrix.dart';

class ReplyContentWidget extends StatelessWidget {
  const ReplyContentWidget({
    super.key,
    required this.event,
    required this.timeline,
    required this.scrollToEventId,
    required this.alignment,
    required this.overlap,
  });

  final Event event;
  final Timeline timeline;
  final void Function(String p1)? scrollToEventId;
  final CrossAxisAlignment alignment;

  /// How much of the quote the widget below it covers.
  final double overlap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event?>(
      future: event.getReplyEvent(timeline),
      builder: (context, snapshot) {
        Event? replyEvent;
        if (snapshot.data != null) {
          replyEvent = snapshot.data;
        } else if (event.relationshipEventId != null) {
          replyEvent = Event(
            eventId: event.relationshipEventId!,
            content: {'msgtype': 'm.text', 'body': '...'},
            senderId: event.senderId,
            type: 'm.room.message',
            room: event.room,
            status: EventStatus.sent,
            originServerTs: DateTime.now(),
          );
        }

        if (replyEvent == null) return const SizedBox();

        return _OverlappedBelow(
          overlap: overlap,
          child: OptionalInkWell(
            onTap: () => scrollToEventId?.call(replyEvent!.eventId),
            isEnabled: scrollToEventId != null,
            child: ReplyContent(
              replyEvent,
              timeline: timeline,
              quoteAlignment: alignment,
              quoteOverlap: overlap,
              // The placeholder borrows the sender of the reply.
              quoteSenderUnknown: snapshot.data == null,
            ),
          ),
        );
      },
    );
  }
}

/// Takes [overlap] less height than its child, so that the next widget of a
/// column is painted over the bottom of it. A [Column] has no negative spacing.
class _OverlappedBelow extends SingleChildRenderObjectWidget {
  const _OverlappedBelow({required this.overlap, required super.child});

  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverlappedBelow(overlap);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderOverlappedBelow renderObject,
  ) => renderObject.overlap = overlap;
}

class _RenderOverlappedBelow extends RenderProxyBox {
  _RenderOverlappedBelow(this._overlap);

  double _overlap;

  double get overlap => _overlap;

  set overlap(double value) {
    if (value == _overlap) return;
    _overlap = value;
    markNeedsLayout();
  }

  Size _shorten(Size size) => Size(size.width, size.height - _overlap);

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) - _overlap;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) - _overlap;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _shorten(super.computeDryLayout(constraints));

  @override
  void performLayout() {
    child!.layout(constraints, parentUsesSize: true);
    size = _shorten(child!.size);
  }
}
