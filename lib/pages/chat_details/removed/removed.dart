import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view_style.dart';
import 'package:fluffychat/pages/chat_details/removed/removed_search_state.dart';
import 'package:fluffychat/pages/chat_details/removed/removed_view.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class Removed extends StatefulWidget {
  final Room room;

  const Removed({super.key, required this.room});

  @override
  RemovedController createState() => RemovedController();
}

class RemovedController extends State<Removed> with SearchDebouncerMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  final ValueNotifier<Either<Failure, Success>> searchUserResults =
      ValueNotifier<Either<Failure, Success>>(
    Right(
      RemovedSearchInitialState(),
    ),
  );

  void onBack() {
    Navigator.of(context).pop();
  }

  List<User> get removedMember => widget.room.getBannedMembers();

  void initialRemoved() {
    searchUserResults.value = Right(
      RemovedSearchSuccessState(
        removedMember: removedMember,
        keyword: '',
      ),
    );
  }

  void handleSearchResults(String searchTerm) {
    if (searchTerm.isEmpty) {
      searchUserResults.value = Right(
        RemovedSearchSuccessState(
          removedMember: removedMember,
          keyword: '',
        ),
      );
      return;
    }

    final searchResults = removedMember.where((user) {
      return (user.displayName ?? '')
              .toLowerCase()
              .contains(searchTerm.toLowerCase()) ||
          (user.id).toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();

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
  Widget build(BuildContext context) {
    return SizedBox(
      width: ChatDetailEditViewStyle.fixedWidth,
      child: RemovedView(controller: this),
    );
  }
}
