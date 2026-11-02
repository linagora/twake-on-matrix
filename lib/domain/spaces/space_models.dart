import 'package:freezed_annotation/freezed_annotation.dart';

part 'space_models.freezed.dart';

/// What the home of a space shows.
@freezed
abstract class SpaceSummary with _$SpaceSummary {
  const factory SpaceSummary({
    required String id,
    required String name,
    required int memberCount,

    /// Anyone may join.
    required bool isPublic,
    required bool canInvite,
    required bool canAddChildren,
    Uri? avatar,
    @Default('') String topic,
  }) = _SpaceSummary;
}

/// A room or sub-space a space lists, joined or not.
@freezed
abstract class SpaceChannel with _$SpaceChannel {
  const factory SpaceChannel({
    required String roomId,
    required String name,
    Uri? avatar,
    @Default(0) int memberCount,
    @Default(false) bool isSpace,
    @Default(false) bool isJoined,

    /// Open to anyone or to the members of the space.
    @Default(false) bool isJoinable,

    /// The servers the space names to join it through.
    @Default(<String>[]) List<String> via,

    /// A valid `order` of its `m.space.child`, if any.
    String? order,

    /// The time of its `m.space.child`, in milliseconds.
    int? listedAt,
  }) = _SpaceChannel;
}

/// The children of a space in the order of the Matrix spec (« Ordering of
/// children within a space »): an `order` first, by code point; then the time
/// of their `m.space.child`; then the room id.
List<SpaceChannel> orderSpaceChildren(List<SpaceChannel> children) {
  const unknownTime = 1 << 53;
  int compare(SpaceChannel a, SpaceChannel b) {
    final orderA = a.order;
    final orderB = b.order;
    if (orderA != null && orderB == null) return -1;
    if (orderA == null && orderB != null) return 1;
    final byOrder = (orderA ?? '').compareTo(orderB ?? '');
    if (byOrder != 0) return byOrder;
    final byTime = (a.listedAt ?? unknownTime).compareTo(
      b.listedAt ?? unknownTime,
    );
    return byTime != 0 ? byTime : a.roomId.compareTo(b.roomId);
  }

  return [...children]..sort(compare);
}

/// The sub-spaces offered under a space in the room list: not joined yet, and
/// open to the user. Private ones and channels stay out of the list.
List<SpaceChannel> joinableSubspaces(List<SpaceChannel> children) => children
    .where((child) => child.isSpace && child.isJoinable && !child.isJoined)
    .toList();
