import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/pages/chat_search/chat_search_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatSearch extends StatefulWidget {
  final VoidCallback? onBack;
  final String roomId;
  const ChatSearch({super.key, this.onBack, required this.roomId});

  @override
  State<ChatSearch> createState() => ChatSearchController();
}

class ChatSearchController extends State<ChatSearch> {
  static const _debouncerDuration = Duration(milliseconds: 300);
  Timeline? _timeline;

  Room? get room => Matrix.of(context).client.getRoomById(widget.roomId);

  Future<Timeline> getTimeline() async {
    _timeline ??= await room?.getTimeline();
    return _timeline!;
  }

  final textEditingController = TextEditingController();

  final debouncer = Debouncer(_debouncerDuration, initialValue: '');

  @override
  Widget build(BuildContext context) {
    return ChatSearchView(this);
  }
}
