import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/model/room/room_preview_result.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatListSortRooms extends StatefulWidget {
  const ChatListSortRooms({
    super.key,
    required this.rooms,
    required this.builder,
    required this.sortingRoomsNotifier,
  });

  final List<Room> rooms;
  final Widget Function(
    List<Room> sortedRooms,
    Map<String, RoomPreviewResult?> previewByRoomId,
  )
  builder;
  final ValueNotifier<bool> sortingRoomsNotifier;

  @override
  State<ChatListSortRooms> createState() => _ChatListSortRoomsState();
}

class _ChatListSortRoomsState extends State<ChatListSortRooms> {
  Map<String, RoomPreviewResult?> _previewByRoomId = {};
  List<Room> _sortCache = [];
  Map<String, StreamSubscription?> _roomSubscriptions = {};
  Future<List<Room>>? _sortFuture;

  /// Monotonically increasing counter to invalidate stale sort futures.
  /// Each call to [_triggerSort] increments this value. When a sort future
  /// completes, it checks whether its generation matches [_sortGeneration].
  /// If not, the result is discarded (a newer sort has been triggered).
  int _sortGeneration = 0;

  DateTime? _previewTs(String roomId) {
    final result = _previewByRoomId[roomId];
    return result is RoomPreviewFound ? result.event.originServerTs : null;
  }

  RoomSorter sortRoomsBy(Client client) => (a, b) {
    if (client.pinInvitedRooms &&
        a.membership != b.membership &&
        [a.membership, b.membership].any((m) => m == Membership.invite)) {
      return a.membership == Membership.invite ? -1 : 1;
    }
    if (a.isFavourite != b.isFavourite) {
      return a.isFavourite ? -1 : 1;
    }
    if (client.pinUnreadRooms && a.notificationCount != b.notificationCount) {
      return b.notificationCount.compareTo(a.notificationCount);
    }
    return (_previewTs(b.id) ?? b.latestEventReceivedTime)
        .millisecondsSinceEpoch
        .compareTo(
          (_previewTs(a.id) ?? a.latestEventReceivedTime)
              .millisecondsSinceEpoch,
        );
  };

  Future<List<Room>> _sortRooms(int generation) async {
    await Matrix.of(context).initSettingsCompleter.future;
    for (final room in widget.rooms) {
      // Bail out early if the widget was disposed or a newer sort was
      // triggered while we were awaiting.
      if (!mounted || generation != _sortGeneration) return _sortCache;

      if (_previewByRoomId[room.id] != null) continue;

      final result = await room.lastEventAvailableInPreview();

      if (!mounted || generation != _sortGeneration) return _sortCache;

      _previewByRoomId[room.id] = result;
    }

    if (!mounted) return _sortCache;

    widget.sortingRoomsNotifier.value = false;
    return List.from(widget.rooms)
      ..sort(sortRoomsBy(Matrix.of(context).client));
  }

  void _triggerSort() {
    _sortGeneration++;
    _sortFuture = _sortRooms(_sortGeneration);
  }

  @override
  void initState() {
    super.initState();
    _previewByRoomId = Map.fromEntries(
      widget.rooms.map((room) => MapEntry(room.id, null)),
    );
    _roomSubscriptions = Map.fromEntries(
      widget.rooms.map(
        (room) => MapEntry(
          room.id,
          room.onUpdate.stream.listen((roomId) {
            _previewByRoomId[roomId] = null;
          }),
        ),
      ),
    );
    _triggerSort();
  }

  @override
  void didUpdateWidget(covariant ChatListSortRooms oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previewByRoomId = Map.fromEntries(
      widget.rooms.map(
        (room) => MapEntry(
          room.id,
          _previewByRoomId.putIfAbsent(room.id, () => null),
        ),
      ),
    );
    final removedRooms = oldWidget.rooms
        .whereNot(widget.rooms.contains)
        .toList();
    for (final room in removedRooms) {
      _roomSubscriptions[room.id]?.cancel();
    }
    _roomSubscriptions = Map.fromEntries(
      widget.rooms.map(
        (room) => MapEntry(
          room.id,
          _roomSubscriptions.putIfAbsent(
            room.id,
            () => room.onUpdate.stream.listen((roomId) {
              _previewByRoomId[roomId] = null;
            }),
          ),
        ),
      ),
    );
    _triggerSort();
  }

  @override
  void dispose() {
    for (final subscription in _roomSubscriptions.values) {
      subscription?.cancel();
    }
    _roomSubscriptions.clear();
    // Invalidate any in-flight sort future so its callbacks become no-ops.
    _sortGeneration++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sortFuture,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          _sortCache = snapshot.data!;
        }

        return widget.builder(
          _sortCache.isEmpty ? widget.rooms : _sortCache,
          _previewByRoomId,
        );
      },
    );
  }
}
