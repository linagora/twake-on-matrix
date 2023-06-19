import 'package:fluffychat/pages/chat/send_file_dialog.dart';
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

  final ActiveFilter _activeFilterAllChats = ActiveFilter.allChats;

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

  List<Room> get filteredRoomsForAll => Matrix.of(context)
    .client
    .rooms
    .where(getRoomFilterByActiveFilter(_activeFilterAllChats))
    .toList();


  Future<void> _forwardMessage(Map<String, dynamic> message, Room room) async {
    final shareFile = message.tryGet<MatrixFile>('file');
    if (message.tryGet<String>('msgtype') == 'chat.fluffy.shared_file' && shareFile != null) {
      await showDialog(
        context: context,
        useRootNavigator: false,
        builder: (c) => SendFileDialog(
          files: [shareFile],
          room: room)
      );
    } else {
      await room.sendEvent(message);
    }
  }

  void _forwardOneMessageAction(BuildContext context, Room room) async {
    final message = Matrix.of(context).shareContent;
    if (message != null) {
      await _forwardMessage(message, room);
      Matrix.of(context).shareContent = null;
    }
    VRouter.of(context).toSegments(['rooms', room.id]);
  }

  void _forwardMoreMessageAction(BuildContext context, Room room) async {
    final messages = Matrix.of(context).shareContentList;
    if (messages.isNotEmpty) {
      for (final message in messages) {
        if (message != null) {
          await _forwardMessage(message, room);
        } else {
          continue;
        }
      }
      Matrix.of(context).shareContentList.clear();
    }
    VRouter.of(context).toSegments(['rooms', room.id]);
  }

  void forwardAction(BuildContext context) async {
    final rooms = filteredRoomsForAll;
    final room = rooms.firstWhere((element) => element.id == selectedEvents.first);
    if (room.membership == Membership.join) {
      if (Matrix.of(context).shareContentList.isEmpty && Matrix.of(context).shareContent != null) {
        _forwardOneMessageAction(context, room);
      } else {
        _forwardMoreMessageAction(context, room);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ForwardView(this);
}

enum EmojiPickerType { reaction, keyboard }
