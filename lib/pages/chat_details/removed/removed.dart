import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/utils/user_extension.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/room/unban_user_state.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/domain/usecase/room/unban_user_interactor.dart';
import 'package:twake_chat/pages/chat_details/chat_details_edit_view_style.dart';
import 'package:twake_chat/pages/chat_details/removed/removed_search_state.dart';
import 'package:twake_chat/pages/chat_details/removed/removed_view.dart';
import 'package:twake_chat/pages/search/search_debouncer_mixin.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

class Removed extends StatefulWidget {
  final Room room;

  const Removed({super.key, required this.room});

  @override
  RemovedController createState() => RemovedController();
}

class RemovedController extends State<Removed> with SearchDebouncerMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  final _unbanUserInteractor = getIt.get<UnbanUserInteractor>();

  StreamSubscription? _unbanUserSubscription;

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  final ValueNotifier<Either<Failure, Success>> searchUserResults =
      ValueNotifier<Either<Failure, Success>>(
        Right(RemovedSearchInitialState()),
      );

  void onBack() {
    Navigator.of(context).pop();
  }

  List<User> get removedMember => widget.room.getBannedMembers();

  void initialRemoved() {
    searchUserResults.value = Right(
      RemovedSearchSuccessState(removedMember: removedMember, keyword: ''),
    );
  }

  void handleSearchResults(String searchTerm) {
    if (searchTerm.isEmpty) {
      searchUserResults.value = Right(
        RemovedSearchSuccessState(removedMember: removedMember, keyword: ''),
      );
      return;
    }

    final searchResults = removedMember.searchUsers(searchTerm);

    Logs().d(
      "RemovedController::handleSearchResults: $searchTerm, results: ${searchResults.length}",
    );

    if (searchResults.isEmpty) {
      searchUserResults.value = Left(
        RemovedSearchEmptyState(keyword: searchTerm),
      );
      return;
    }

    searchUserResults.value = Right(
      RemovedSearchSuccessState(
        removedMember: searchResults,
        keyword: searchTerm,
      ),
    );
  }

  void handleOnTapUnbanUser(User user) async {
    Logs().d("RemovedController::handleOnTapUnbanUser");
    _unbanUserSubscription = _unbanUserInteractor
        .execute(user: user)
        .listen((result) => handleUnbanState(result));
  }

  void handleUnbanState(Either<Failure, Success> state) {
    state.fold(
      (failure) {
        if (failure is UnbanUserFailure) {
          TwakeDialog.hideLoadingDialog(context);
          TwakeSnackBar.show(context, failure.exception.toString());
          return;
        }

        if (failure is NoPermissionForUnbanFailure) {
          TwakeDialog.hideLoadingDialog(context);
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.permissionErrorUnbanUser,
          );
          return;
        }
      },
      (success) {
        if (success is UnbanUserLoading) {
          TwakeDialog.showLoadingDialog(context);
          return;
        }

        if (success is UnbanUserSuccess) {
          refreshRemoved();
          return;
        }
      },
    );
  }

  void refreshRemoved() {
    Future.delayed(const Duration(milliseconds: 300)).then((_) {
      TwakeDialog.hideLoadingDialog(context);

      if (removedMember.isEmpty) {
        Navigator.pop(context);
        return;
      }
      initialRemoved();
    });
  }

  @override
  void initState() {
    initialRemoved();
    textEditingController.addListener(
      () => setDebouncerValue(textEditingController.text),
    );
    initializeDebouncer((searchTerm) {
      Logs().d("RemovedController::initState: $searchTerm");
      handleSearchResults(searchTerm);
    });
    super.initState();
  }

  @override
  void dispose() {
    _unbanUserSubscription?.cancel();
    textEditingController.dispose();
    inputFocus.dispose();
    searchUserResults.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ChatDetailEditViewStyle.fixedWidth,
      child: RemovedView(controller: this),
    );
  }
}
