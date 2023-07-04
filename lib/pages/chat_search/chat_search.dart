import 'package:fluffychat/pages/chat_search/chat_search_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ChatSearch extends StatefulWidget {
  const ChatSearch({super.key});

  @override
  State<ChatSearch> createState() => ChatSearchController();
}

class ChatSearchController extends State<ChatSearch> {

  AutoScrollController recentChatsController = AutoScrollController();
  ScrollController customScrollController = ScrollController();

  isFilteredRecentChat(Room room) {
    return !room.isSpace && room.isDirectChat && !room.isStoryRoom;
  }

  List<Room> get filteredRoomsForAll => Matrix.of(context)
    .client
    .rooms
    .where((room) => !room.isSpace && !room.isStoryRoom)
    .toList();

  @override
  void dispose() {
    recentChatsController.dispose();
    customScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChatSearchView(this);
}
