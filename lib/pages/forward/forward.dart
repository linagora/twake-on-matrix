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

  late MatrixState _matrixState;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _matrixState = Matrix.of(context);
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
    _matrixState.shareContent = null;
    _matrixState.shareContentList = null;
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
    await forwardMessageInteractorStreamSubscription?.cancel();
    // asyncMap enforces sequential event handling: the next event is not
    // processed until the async handler for the current one completes.
    // This prevents ForwardMessageAllDoneState from triggering navigation
    // while a SendFileDialog is still awaiting user input.
    forwardMessageInteractorStreamSubscription = _forwardMessageInteractor
        .execute(
          rooms: filteredRoomsForAll,
          selectedEvents: selectedRoomIdNotifier.value,
          matrixState: Matrix.of(context),
        )
        .asyncMap((event) => _handleForwardMessageOnData(context, event))
        .listen(
          (_) {},
          onDone: _handleForwardMessageOnDone,
          onError: _handleForwardMessageOnError,
        );
  }

  Future<void> _handleForwardMessageOnData(
    BuildContext context,
    Either<Failure, Success> event,
  ) async {
    Logs().d('ForwardController::_handleForwardMessageOnData()');
    forwardMessageNotifier.value = event;
    await event.fold(
      (failure) async {
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
            _handleAllDone(success);
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

  void _handleAllDone(ForwardMessageAllDoneState done) {
    final navigator = Navigator.of(context);
    if (!mounted) return;
    if (done.totalCount != 1) {
      final message = _buildMultiForwardSnackbarMessage(done);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        const RoomsRoute().go(context);
      }
      TwakeSnackBar.show(context, message);
      return;
    }

    if (done.successCount == 0) {
      TwakeSnackBar.show(context, L10n.of(context)!.forwardFailed);
      return;
    }

    final roomId = selectedRoomIdNotifier.value.firstOrNull;
    if (navigator.canPop()) {
      navigator.pop(const PopResultFromForward());
    }
    if (roomId != null) {
      RoomRoute(roomid: roomId).go(context);
    }
  }

  String _buildMultiForwardSnackbarMessage(ForwardMessageAllDoneState done) {
    final l10n = L10n.of(context)!;
    if (done.successCount == 0) {
      return l10n.forwardFailed;
    }
    if (done.successCount == done.totalCount) {
      return l10n.forwardedToChats(done.successCount);
    }
    return l10n.forwardedToChatsPartial(done.successCount, done.totalCount);
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
