import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/forward/forward_controller.dart';
import 'package:twake_chat/pages/forward/forward_state.dart';
import 'package:twake_chat/pages/forward/forward_view.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/presentation/model/pop_result_from_forward.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/utils/search/search_options.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';

class Forward extends ConsumerStatefulWidget {
  final List<Map<String, Object?>> messages;
  final bool? isFullScreen;

  const Forward({super.key, required this.messages, this.isFullScreen = true});

  @override
  ForwardScreenState createState() => ForwardScreenState();
}

class ForwardScreenState extends ConsumerState<Forward> {
  final searchTextEditingController = TextEditingController();

  final searchFocusNode = FocusNode();

  final isSearchModeNotifier = ValueNotifier(false);

  final recentChatScrollController = AutoScrollController();

  late final List<Room> _rooms;

  late List<Room> recentChats;

  final selectedRoomIdsNotifier = ValueNotifier<List<String>>([]);

  List<String> get selectedRoomIds => selectedRoomIdsNotifier.value;

  String _keyword = '';

  bool get isFullScreen => widget.isFullScreen == true;

  @override
  void initState() {
    super.initState();
    _rooms = ref.read(activeMatrixClientProvider)?.acceptedRooms ?? [];
    recentChats = _rooms;
    searchTextEditingController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchTextEditingController.dispose();
    searchFocusNode.dispose();
    isSearchModeNotifier.dispose();
    selectedRoomIdsNotifier.dispose();
    recentChatScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final keyword = searchTextEditingController.text;
    if (keyword == _keyword) return;
    _keyword = keyword;
    final matrixLocals = MatrixLocals(L10n.of(context)!);
    setState(() {
      recentChats = keyword.isEmpty
          ? _rooms
          : const SearchEngine().match(
              keyword,
              _rooms,
              fieldExtractors: [
                (Room room) => [room.getLocalizedDisplayname(matrixLocals)],
              ],
              options: const SearchOptions(diacriticSensitive: false),
            );
    });
  }

  void openSearchBar() {
    isSearchModeNotifier.value = true;
    searchFocusNode.requestFocus();
  }

  void closeSearchBar() {
    searchTextEditingController.clear();
    searchFocusNode.unfocus();
    isSearchModeNotifier.value = false;
  }

  void onToggleSelectChat(String roomId) {
    if (ref.read(forwardControllerProvider) is ForwardSending) return;
    selectedRoomIdsNotifier.value = selectedRoomIds.contains(roomId)
        ? selectedRoomIds.where((id) => id != roomId).toList()
        : [...selectedRoomIds, roomId];
  }

  void forwardAction() => unawaited(
    ref
        .read(forwardControllerProvider.notifier)
        .forward(messages: widget.messages, roomIds: selectedRoomIds),
  );

  void _onStateChanged(ForwardState? previous, ForwardState next) {
    switch (next) {
      case ForwardSending():
        TwakeDialog.showLoadingDialog(context);
      case ForwardDone():
        TwakeDialog.hideLoadingDialog(context);
        _handleAllDone(next);
      case ForwardIdle():
        if (previous is! ForwardSending) return;
        TwakeDialog.hideLoadingDialog(context);
        TwakeSnackBar.show(context, L10n.of(context)!.forwardFailed);
    }
  }

  void _handleAllDone(ForwardDone done) {
    if (done.successCount == 0 && done.partialCount == 0) {
      TwakeSnackBar.show(context, L10n.of(context)!.forwardFailed);
      return;
    }

    final navigator = Navigator.of(context);
    if (done.totalCount != 1 || done.successCount == 0) {
      final message = _buildMultiForwardSnackbarMessage(done);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        const RoomsRoute().go(context);
      }
      TwakeSnackBar.show(context, message);
      return;
    }

    final roomId = selectedRoomIds.firstOrNull;
    if (navigator.canPop()) {
      navigator.pop(const PopResultFromForward());
    }
    if (roomId != null) {
      RoomRoute(roomid: roomId).go(context);
    }
  }

  String _buildMultiForwardSnackbarMessage(ForwardDone done) {
    final l10n = L10n.of(context)!;
    if (done.successCount == done.totalCount) {
      return l10n.forwardedToChats(done.successCount);
    }
    return l10n.forwardedToChatsPartial(done.successCount, done.totalCount);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(forwardControllerProvider, _onStateChanged);
    return ForwardView(this);
  }
}
