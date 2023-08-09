import 'dart:async';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/go_routes/go_router.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/forward/forward_message_state.dart';
import 'package:fluffychat/domain/usecase/forward/forward_message_interactor.dart';
import 'package:fluffychat/pages/chat/send_file_dialog.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:fluffychat/widgets/matrix.dart';

class Forward extends StatefulWidget {
  const Forward({Key? key}) : super(key: key);

  @override
  ForwardController createState() => ForwardController();
}

class ForwardController extends State<Forward> {
  final _forwardMessageInteractor = getIt.get<ForwardMessageInteractor>();

  final forwardMessageNotifier = ValueNotifier<Either<Failure, Success>?>(null);

  StreamSubscription? forwardMessageInteractorStreamSubscription;

  List<Room>? rooms;

  Timeline? timeline;

  String? get roomId => GoRouterState.of(context).pathParameters['roomid'];

  final AutoScrollController forwardListController = AutoScrollController();

  List<String> selectedEvents = [];

  bool get selectMode => selectedEvents.isNotEmpty;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    forwardListController.dispose();
    forwardMessageInteractorStreamSubscription?.cancel();
    super.dispose();
  }

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

  void forwardAction(BuildContext context) async {
    forwardMessageInteractorStreamSubscription = _forwardMessageInteractor
        .execute(
          rooms: filteredRoomsForAll,
          selectedEvents: selectedEvents,
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
    event.fold((failure) {
      Logs().e(
        'ForwardController::_handleForwardMessageOnData() - failure: $failure',
      );
    }, (success) async {
      Logs().d(
        'ForwardController::_handleForwardMessageOnData() - success: $success',
      );
      switch (success.runtimeType) {
        case ForwardMessageSuccess:
          final dataOnSuccess = success as ForwardMessageSuccess;
          context.go('${goShellBranch()}/${dataOnSuccess.room.id}');
          break;
        case ForwardMessageIsShareFileState:
          final dataOnSuccess = success as ForwardMessageIsShareFileState;
          await showDialog(
            context: context,
            useRootNavigator: false,
            builder: (c) => SendFileDialog(
              files: [dataOnSuccess.shareFile],
              room: dataOnSuccess.room,
            ),
          );
          break;
      }
    });
  }

  String goShellBranch() {
    final currentShellBranch = GoRouterState.of(context).fullPath;
    Logs().d(
      'Forward()::goShellBranch() currentShellBranch: $currentShellBranch',
    );
    return TwakeRoutes.shellBranch.firstWhere(
      (branch) => currentShellBranch?.startsWith('$branch/') == true,
    );
  }

  void _handleForwardMessageOnDone() {
    Logs().d('ForwardController::_handleForwardMessageOnDone()');
  }

  void _handleForwardMessageOnError(dynamic error, StackTrace? stackTrace) {
    Logs().e(
      'ForwardController::_handleForwardMessageOnError() - error: $error | stackTrace: $stackTrace',
    );
  }

  @override
  Widget build(BuildContext context) => ForwardView(this);
}

enum EmojiPickerType { reaction, keyboard }
