/// What the new group flow makes.
enum NewGroupKind {
  group,
  feed,
  space;

  bool get isFeed => this == NewGroupKind.feed;

  bool get isSpace => this == NewGroupKind.space;

  /// A space, or a channel its members can join, may start with nobody else.
  bool isMemberRequired({String? parentSpaceId}) =>
      !isSpace && parentSpaceId == null;
}
