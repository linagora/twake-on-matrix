import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat/events/images_builder/media_album_scope.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

/// The id an album of timeline events is keyed by.
String mediaAlbumEventId(Event event) => event.eventId;

/// The [MediaAlbumScope] helpers for timeline events.
extension MediaAlbumContextExtension on BuildContext {
  /// The images drawn in the bubble of [event] when it leads an album
  /// (oldest first), else null.
  List<Event>? albumMembersFor(Event event) =>
      MediaAlbumScope.membersFor<Event>(this, event.eventId);

  /// The events whose reactions the bubble of [event] shows: every image of
  /// the album it leads, else [event] alone.
  List<Event> albumEventsOf(Event event) => albumMembersFor(event) ?? [event];

  /// Whether the bubble of [event] has text under its media: its own caption
  /// or reply, or, for the leader of an album, the caption of the last image.
  bool albumHasCaptionOrReply(Event event) =>
      event.isCaptionModeOrReply() ||
      (albumMembersFor(event)?.last.isCaptionModeOrReply() ?? false);

  /// Whether the time sits over the media, as for an image with no caption.
  bool albumTimelineOverlayFor(Event event) =>
      event.timelineOverlayMessage && !albumHasCaptionOrReply(event);
}
