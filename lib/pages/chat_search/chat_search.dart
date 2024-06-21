import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_search/chat_search_view.dart';
import 'package:fluffychat/pages/search/server_search_controller.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatSearch extends StatefulWidget {
  final VoidCallback? onBack;
  final String roomId;
  final bool isInStack;

  const ChatSearch({
    super.key,
    this.onBack,
    required this.roomId,
    required this.isInStack,
  });

  @override
  State<ChatSearch> createState() => ChatSearchController();
}

class ChatSearchController extends State<ChatSearch> {
  static const _pageLimit = 20;
  Timeline? _timeline;

  Room? get room => Matrix.of(context).client.getRoomById(widget.roomId);

  Future<Timeline> getTimeline() async {
    _timeline ??= await room?.getTimeline();
    return _timeline!;
  }

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  SameTypeEventsBuilderController? sameTypeEventsBuilderController;

  late ServerSearchController serverSearchController;

  final scrollController = ScrollController();

  @override
  void initState() {
    serverSearchController = ServerSearchController(
      inRoomId: widget.roomId,
    );
    _initSearchInsideChat();
    scrollController.addLoadMoreListener(loadMore);
    textEditingController.addListener(
      () => serverSearchController.setDebouncerValue(
        textEditingController.text,
      ),
    );
    serverSearchController.initSearch(
      context: context,
      onSearchEncryptedMessage: sameTypeEventsBuilderController != null
          ? _listenSearchEncryptedMessage
          : null,
    );
    super.initState();
  }

  void loadMore() {
    if (sameTypeEventsBuilderController != null) {
      sameTypeEventsBuilderController!.loadMore();
    } else {
      serverSearchController.loadMore();
    }
  }

  void _initSearchInsideChat() {
    if (room?.encrypted == true) {
      sameTypeEventsBuilderController = SameTypeEventsBuilderController(
        getTimeline: getTimeline,
        searchFunc: (event) =>
            event.isContains(serverSearchController.debouncerValue) &&
            event.isSearchable,
        limit: _pageLimit,
      );
    }
  }

  void _listenSearchEncryptedMessage(String keyword) {
    if (keyword.length >= AppConfig.chatRoomSearchKeywordMin) {
      sameTypeEventsBuilderController?.refresh(force: true);
    } else {
      sameTypeEventsBuilderController?.clear();
    }
  }

  void onEventTap(Event event) async {
    if (widget.isInStack) {
      await onBack();
    }
    context.goToRoomWithEvent(event.room.id, event.eventId);
  }

  Future onBack() async {
    inputFocus.unfocus();
    return widget.onBack?.call();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    scrollController.dispose();
    sameTypeEventsBuilderController?.dispose();
    serverSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatSearchView(this);
  }
}
