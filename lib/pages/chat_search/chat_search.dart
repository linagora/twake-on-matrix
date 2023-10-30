import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_search/chat_search_view.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatSearch extends StatefulWidget {
  final VoidCallback? onBack;
  final void Function(EventId) jumpToEventId;
  final String roomId;
  final bool isInStack;

  const ChatSearch({
    super.key,
    this.onBack,
    required this.roomId,
    required this.jumpToEventId,
    required this.isInStack,
  });

  @override
  State<ChatSearch> createState() => ChatSearchController();
}

class ChatSearchController extends State<ChatSearch> {
  static const _debouncerDuration = Duration(milliseconds: 300);
  static const _pageLimit = 20;
  Timeline? _timeline;

  Room? get room => Matrix.of(context).client.getRoomById(widget.roomId);

  Future<Timeline> getTimeline() async {
    _timeline ??= await room?.getTimeline();
    return _timeline!;
  }

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  final debouncer = Debouncer(
    _debouncerDuration,
    initialValue: '',
    checkEquality: false,
  );

  SameTypeEventsBuilderController? eventsController;

  final scrollController = ScrollController();

  @override
  void initState() {
    eventsController = SameTypeEventsBuilderController(
      getTimeline: getTimeline,
      searchFunc: (event) =>
          event.isContains(debouncer.value) && event.isSearchable,
      limit: _pageLimit,
    );
    scrollController.addLoadMoreListener(eventsController!.loadMore);
    textEditingController.addListener(() {
      debouncer.value = textEditingController.text;
    });
    debouncer.values.listen((text) {
      if (text.length >= AppConfig.chatRoomSearchKeywordMin) {
        eventsController?.refresh(force: true);
      } else {
        eventsController?.clear();
      }
    });
    super.initState();
  }

  void onEventTap(Event event) async {
    if (widget.isInStack) {
      await onBack();
    }
    widget.jumpToEventId(event.eventId);
  }

  Future onBack() async {
    inputFocus.unfocus();
    return widget.onBack?.call();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatSearchView(this);
  }
}
