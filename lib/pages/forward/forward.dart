import 'dart:async';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/forward/forward_message_state.dart';
import 'package:fluffychat/domain/usecase/forward/forward_message_interactor.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:fluffychat/presentation/mixins/search_recent_chat_mixin.dart';
import 'package:fluffychat/presentation/model/pop_result_from_forward.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluffychat/config/go_routes/app_routes.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:fluffychat/widgets/matrix.dart';

class Forward extends StatefulWidget {
  final String? sendFromRoomId;
  final bool? isFullScreen;

  const Forward({super.key, this.sendFromRoomId, this.isFullScreen = true});

  @override
  ForwardController createState() => ForwardController();
}

class ForwardController extends State<Forward>
    with SearchRecentChat, ContactsViewControllerMixin {
  final _forwardMessageInteractor = getIt.get<ForwardMessageInteractor>();

  final forwardMessageNotifier = ValueNotifier<Either<Failure, Success>?>(null);

  StreamSubscription? forwardMessageInteractorStreamSubscription;

  List<Room>? rooms;

  String? sendFromRoomId;

  String? get roomId => widget.sendFromRoomId;

  bool get isFullScreen => widget.isFullScreen == true;

  final AutoScrollController recentChatScrollController =
      AutoScrollController();

  final selectedRoomIdNotifier = ValueNotifier(<String>[]);

  @override
  void closeSearchBar() {
    searchTextEditingController.clear();
    super.closeSearchBar();
  }

  @override
  void initState() {
    super.initState();
    sendFromRoomId = widget.sendFromRoomId;
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
    forwardMessageNotifier.dispose();
    disposeContactsMixin();
    recentChatScrollController.dispose();
    forwardMessageInteractorStreamSubscription?.cancel();
    // Clear share state in case the stream was cancelled mid-operation
    // and the interactor's own cleanup lines never executed.
    final matrixState = Matrix.of(context);
    matrixState.shareContent = null;
    matrixState.shareContentList = null;
    disposeSearchRecentChat();
    selectedRoomIdNotifier.dispose();
    super.dispose();
  }

  void onToggleSelectChat(String id) {
    final current = List<String>.from(selectedRoomIdNotifier.value);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    selectedRoomIdNotifier.value = current;
  }

  final ActiveFilter _activeFilterAllChats = ActiveFilter.acceptedChats;

  List<Room> get filteredRoomsForAll =>
      Matrix.of(context).client.filteredRoomsForAll(_activeFilterAllChats);

  void forwardAction() async {
    forwardMessageInteractorStreamSubscription = _forwardMessageInteractor
        .execute(
          rooms: filteredRoomsForAll,
          selectedEvents: selectedRoomIdNotifier.value,
          matrixState: Matrix.of(context),
        )
        .listen(
          (event) => _handleForwardMessageOnData(context, event),
          onDone: _handleForwardMessageOnDone,
          onError: _handleForwardMessageOnError,
        );
  }

  void _handleForwardMessageOnData(
    BuildContext context,
    Either<Failure, Success> event,
  ) {
    Logs().d('ForwardController::_handleForwardMessageOnData()');
    forwardMessageNotifier.value = event;
    event.fold(
      (failure) {
        Logs().e(
          'ForwardController::_handleForwardMessageOnData() - failure: $failure',
        );
        if (mounted) {
          TwakeDialog.hideLoadingDialog(context);
        }
      },
      (success) async {
        Logs().d(
          'ForwardController::_handleForwardMessageOnData() - success: $success',
        );
        if (!mounted) return;
        if (success is ForwardMessageLoading) {
          TwakeDialog.showLoadingDialog(context);
        } else if (success is ForwardMessageAllDoneState) {
          TwakeDialog.hideLoadingDialog(context);
        }
        if (!mounted) return;
        switch (success) {
          case ForwardMessageAllDoneState():
            _handleAllDone(context, success);
            break;
          case ForwardMessageIsShareFileState(:final shareFile, :final room):
            await showDialog(
              context: context,
              useRootNavigator: false,
              builder: (c) => SendFileDialog(files: [shareFile], room: room),
            );
            break;
        }
      },
    );
  }

  void _handleAllDone(BuildContext context, ForwardMessageAllDoneState done) {
    if (!mounted) return;
    if (done.totalCount != 1) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        const RoomsRoute().go(context);
      }
      final message = _buildMultiForwardSnackbarMessage(context, done);
      TwakeSnackBar.show(context, message);
      return;
    }

    if (done.successCount == 0) {
      TwakeSnackBar.show(context, L10n.of(context)!.forwardFailed);
      return;
    }

    final roomId = selectedRoomIdNotifier.value.firstOrNull;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(const PopResultFromForward());
    }
    if (roomId != null) {
      RoomRoute(roomid: roomId).go(context);
    }
  }

  String _buildMultiForwardSnackbarMessage(
    BuildContext context,
    ForwardMessageAllDoneState done,
  ) {
    if (done.successCount == 0) {
      return L10n.of(context)!.forwardFailed;
    }
    if (done.successCount == done.totalCount) {
      return L10n.of(context)!.forwardedToChats(done.successCount);
    }
    return L10n.of(
      context,
    )!.forwardedToChatsPartial(done.successCount, done.totalCount);
  }

  void _handleForwardMessageOnDone() {
    Logs().d('ForwardController::_handleForwardMessageOnDone()');
  }

  void _handleForwardMessageOnError(dynamic error, StackTrace? stackTrace) {
    Logs().e(
      'ForwardController::_handleForwardMessageOnError() - error: $error | stackTrace: $stackTrace',
    );
  }

  void popScreen() {
    if (widget.sendFromRoomId != null) {
      RoomRoute(roomid: widget.sendFromRoomId!).go(context);
    } else {
      const RoomsRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) => ForwardView(this);
}

enum EmojiPickerType { reaction, keyboard }
