import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

/// Tells the bubble of an album's leader event which images it draws.
class MediaAlbumScope extends InheritedWidget {
  /// Album members, oldest first. The first one is the leader.
  final List<Event> members;

  const MediaAlbumScope({
    super.key,
    required this.members,
    required super.child,
  });

  static List<Event>? membersFor(BuildContext context, Event event) {
    final scope = context.dependOnInheritedWidgetOfExactType<MediaAlbumScope>();
    if (scope == null || scope.members.first.eventId != event.eventId) {
      return null;
    }
    return scope.members;
  }

  /// The events whose reactions the bubble of [event] shows: every image of
  /// the album it leads, else [event] alone.
  static List<Event> eventsOf(BuildContext context, Event event) =>
      membersFor(context, event) ?? [event];

  @override
  bool updateShouldNotify(MediaAlbumScope oldWidget) =>
      oldWidget.members.length != members.length ||
      !_sameIds(oldWidget.members, members);

  bool _sameIds(List<Event> a, List<Event> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].eventId != b[i].eventId) return false;
    }
    return true;
  }
}

/// Lets an album tile tell the message around it which image the finger is
/// on, so that a long-press opens the menu of that image.
class MediaAlbumPressScope extends InheritedWidget {
  final void Function(Event event) onPressed;

  const MediaAlbumPressScope({
    super.key,
    required this.onPressed,
    required super.child,
  });

  static void report(BuildContext context, Event event) => context
      .getInheritedWidgetOfExactType<MediaAlbumPressScope>()
      ?.onPressed(event);

  @override
  bool updateShouldNotify(MediaAlbumPressScope oldWidget) => false;
}
