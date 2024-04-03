import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/send_file_interactor.dart';
import 'package:fluffychat/event/twake_event_types.dart';
import 'package:fluffychat/pages/share/share_view.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/mixins/search_recent_chat_mixin.dart';
import 'package:fluffychat/presentation/mixins/send_files_mixin.dart';
import 'package:fluffychat/presentation/model/chat/chat_router_input_argument.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class Share extends StatefulWidget {
  const Share({super.key});

  @override
  State<Share> createState() => ShareController();
}

class ShareController extends State<Share>
    with SendFilesMixin, SearchRecentChat {
  final sendFileInteractor = getIt.get<SendFileInteractor>();

  final isSearchModeNotifier = ValueNotifier(false);

  final AutoScrollController recentChatScrollController =
      AutoScrollController();

  final searchFocusNode = FocusNode();

  final selectedChatNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      listenToSearch(
        context: context,
        filteredRoomsForAll: filteredRoomsForAll,
      );
      recentlyChatsNotifier.value = filteredRoomsForAll;
    });
  }

  @override
  void dispose() {
    isSearchModeNotifier.dispose();
    recentChatScrollController.dispose();
    searchFocusNode.dispose();
    selectedChatNotifier.dispose();
    disposeSearchRecentChat();
    super.dispose();
  }

  void onToggleSelectChat(String id) {
    selectedChatNotifier.value = id;
  }

  void toggleSearchMode() {
    isSearchModeNotifier.toggle();
  }

  void closeSearchBar() {
    searchTextEditingController.clear();
    searchFocusNode.unfocus();
    isSearchModeNotifier.value = false;
  }

  void shareTo(String roomId) async {
    final room = Room(
      id: selectedChatNotifier.value,
      client: Matrix.of(context).client,
    );
    final shareContentList = Matrix.of(context).shareContentList;
    final shareContent = Matrix.of(context).shareContent;

    if (shareContentList.isNotEmpty) {
      _handleShareFilesContent(
        room: room,
        shareContentList: shareContentList,
      );
    } else if (shareContent != null) {
      _handleShareTextContent(
        room: room,
        textContent: shareContent,
      );
    }
  }

  void _handleShareTextContent({
    required Room room,
    Map<String, dynamic>? textContent,
  }) {
    if (textContent == null) return;
    room.sendEvent(textContent);
    context.go('/rooms/${room.id}');
  }

  void _handleShareFilesContent({
    required Room room,
    required List<Map<String, dynamic>?> shareContentList,
  }) {
    if (shareContentList.isNotEmpty) {
      if (shareContentList.every(
        (content) =>
            content?.tryGet<String>('msgtype') ==
            TwakeEventTypes.shareFileEventType,
      )) {
        context.go(
          '/rooms/${room.id}',
          extra: ChatRouterInputArgument(
            type: ChatRouterInputArgumentType.share,
            data: shareContentList
                .map((content) => content?.tryGet<MatrixFile>('file'))
                .toList(),
          ),
        );
      }
      Matrix.of(context).shareContentList = null;
    }
  }

  final ActiveFilter _activeFilterAllChats = ActiveFilter.acceptedChats;

  List<Room> get filteredRoomsForAll =>
      Matrix.of(context).client.filteredRoomsForAll(_activeFilterAllChats);

  @override
  Widget build(BuildContext context) {
    return ShareView(this);
  }
}
