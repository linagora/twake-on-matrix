import 'package:flutter/widgets.dart';

/// Tells the bubble of an album's leader which images it draws.
///
/// Generic over the member type so that this widget does not depend on the
/// Matrix SDK; `MediaAlbumContextExtension` gives the typed helpers for
/// timeline events.
class MediaAlbumScope<T> extends InheritedWidget {
  /// Album members, oldest first. The first one is the leader.
  final List<T> members;

  /// The id of a member, used to find the leader and to compare albums.
  final String Function(T member) idOf;

  const MediaAlbumScope({
    super.key,
    required this.members,
    required this.idOf,
    required super.child,
  });

  /// The members of the album led by [leaderId], else null.
  static List<T>? membersFor<T>(BuildContext context, String? leaderId) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<MediaAlbumScope<T>>();
    if (scope == null ||
        scope.members.isEmpty ||
        scope.idOf(scope.members.first) != leaderId) {
      return null;
    }
    return scope.members;
  }

  @override
  bool updateShouldNotify(MediaAlbumScope<T> oldWidget) =>
      oldWidget.members.length != members.length ||
      !_sameIds(oldWidget.members, members);

  bool _sameIds(List<T> a, List<T> b) {
    for (var i = 0; i < a.length; i++) {
      if (idOf(a[i]) != idOf(b[i])) return false;
    }
    return true;
  }
}

/// Lets an album tile tell the message around it which image the finger is
/// on, so that a long-press opens the menu of that image.
class MediaAlbumPressScope<T> extends InheritedWidget {
  final void Function(T member) onPressed;

  const MediaAlbumPressScope({
    super.key,
    required this.onPressed,
    required super.child,
  });

  static void report<T>(BuildContext context, T member) => context
      .getInheritedWidgetOfExactType<MediaAlbumPressScope<T>>()
      ?.onPressed(member);

  @override
  bool updateShouldNotify(MediaAlbumPressScope<T> oldWidget) => false;
}
