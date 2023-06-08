import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/widgets/matrix.dart';

class Forward extends StatefulWidget {
  final Widget? sideView;

  const Forward({Key? key, this.sideView}) : super(key: key);

  @override
  ForwardController createState() => ForwardController();
}

class ForwardController extends State<Forward> {

  List<Room>? rooms;

  Timeline? timeline;

  String? get roomId => context.vRouter.pathParameters['roomid'];

  final AutoScrollController forwardListController = AutoScrollController();

  List<String> selectedEvents = [];

  bool get selectMode => selectedEvents.isNotEmpty;

  String? get activeChat => VRouter.of(context).pathParameters['roomid'];

  void onSelectChat(String id) {
    if (selectedEvents.contains(id)) {
      setState(
        () => selectedEvents.remove(id),
      );
    } else {
      setState(
        () => selectedEvents.add(id),
      );
    }
    selectedEvents.sort(
          (a, b) => a.compareTo(b),
    );
    Logs().d("onSelectChat: $selectedEvents");
  }

  ActiveFilter activeFilter = AppConfig.separateChatTypes
      ? ActiveFilter.messages
      : ActiveFilter.allChats;

  bool Function(Room) getRoomFilterByActiveFilter(ActiveFilter activeFilter) {
    switch (activeFilter) {
      case ActiveFilter.allChats:
        return (room) => !room.isSpace && !room.isStoryRoom;
      case ActiveFilter.groups:
        return (room) =>
        !room.isSpace && !room.isDirectChat && !room.isStoryRoom;
      case ActiveFilter.messages:
        return (room) =>
        !room.isSpace && room.isDirectChat && !room.isStoryRoom;
      case ActiveFilter.spaces:
        return (r) => r.isSpace;
    }
  }

  List<Room> get filteredRooms => Matrix.of(context)
    .client
    .rooms
    .where(getRoomFilterByActiveFilter(activeFilter))
    .toList();

  @override
  Widget build(BuildContext context) => ForwardView(this);
}

enum EmojiPickerType { reaction, keyboard }
