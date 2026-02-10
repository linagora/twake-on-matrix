import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
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
    Map<String, Event?> lastEventByRoomId,
  )
  builder;
  final ValueNotifier<bool> sortingRoomsNotifier;

  @override
  State<ChatListSortRooms> createState() => _ChatListSortRoomsState();
}

class _ChatListSortRoomsState extends State<ChatListSortRooms> {
  Map<String, Event?> _lastEventByRoomId = {};
  List<Room> _sortCache = [];
  Map<String, StreamSubscription?> _roomSubscriptions = {};

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
    return (_lastEventByRoomId[b.id]?.originServerTs ??
            b.latestEventReceivedTime)
        .millisecondsSinceEpoch
        .compareTo(
          (_lastEventByRoomId[a.id]?.originServerTs ??
                  a.latestEventReceivedTime)
              .millisecondsSinceEpoch,
        );
  };

  Future<List<Room>> sortRooms() async {
    await Matrix.of(context).initSettingsCompleter.future;
    for (final room in widget.rooms) {
      if (_lastEventByRoomId[room.id] != null) continue;

      final event = await room.lastEventAvailableInPreview();
      _lastEventByRoomId[room.id] = event;
    }
    widget.sortingRoomsNotifier.value = false;
    return List.from(widget.rooms)
      ..sort(sortRoomsBy(Matrix.of(context).client));
  }

  @override
  void initState() {
    super.initState();
    _lastEventByRoomId = Map.fromEntries(
      widget.rooms.map((room) => MapEntry(room.id, null)),
    );
    _roomSubscriptions = Map.fromEntries(
      widget.rooms.map(
        (room) => MapEntry(
          room.id,
          room.onUpdate.stream.listen((roomId) {
            _lastEventByRoomId[roomId] = null;
          }),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ChatListSortRooms oldWidget) {
    super.didUpdateWidget(oldWidget);
    _lastEventByRoomId = Map.fromEntries(
      widget.rooms.map(
        (room) => MapEntry(
          room.id,
          _lastEventByRoomId.putIfAbsent(room.id, () => null),
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
              _lastEventByRoomId[roomId] = null;
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sortRooms(),
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          _sortCache = snapshot.data!;
        }

        return widget.builder(
          _sortCache.isEmpty ? widget.rooms : _sortCache,
          _lastEventByRoomId,
        );
      },
    );
  }
}
