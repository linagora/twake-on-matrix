import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/quick_role_picker_mixin.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view_style.dart';
import 'package:fluffychat/pages/chat_details/exceptions/exceptions_search_state.dart';
import 'package:fluffychat/pages/chat_details/exceptions/exceptions_view.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class Exceptions extends StatefulWidget {
  final Room room;

  const Exceptions({super.key, required this.room});

  @override
  ExceptionsController createState() => ExceptionsController();
}

class ExceptionsController extends State<Exceptions>
    with SearchDebouncerMixin, TwakeContextMenuMixin, QuickRolePickerMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  StreamSubscription? _powerLevelsSubscription;

  final ValueNotifier<Either<Failure, Success>> searchUserResults =
      ValueNotifier<Either<Failure, Success>>(
        Right(ExceptionsSearchInitialState()),
      );

  void onBack() {
    Navigator.of(context).pop();
  }

  void refreshView() {
    if (!mounted) return;

    setState(() {});
  }

  List<User> get exceptionsMember => widget.room.getExceptionsMember();

  void initialExceptions() {
    searchUserResults.value = Right(
      ExceptionsSearchSuccessState(
        exceptionsMember: exceptionsMember,
        keyword: '',
      ),
    );
  }

  void handleSearchResults(String searchTerm) {
    if (searchTerm.isEmpty) {
      searchUserResults.value = Right(
        ExceptionsSearchSuccessState(
          exceptionsMember: exceptionsMember,
          keyword: '',
        ),
      );
      return;
    }

    final exceptionUsers = exceptionsMember;

    final searchResults = exceptionUsers.where((user) {
      return (user.displayName ?? '').toLowerCase().contains(
            searchTerm.toLowerCase(),
          ) ||
          (user.id).toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();

    Logs().d(
      "ExceptionsController::handleSearchResults: $searchTerm, results: ${searchResults.length}",
    );

    if (searchResults.isEmpty) {
      searchUserResults.value = Left(
        ExceptionsSearchEmptyState(keyword: searchTerm),
      );
      return;
    }

    searchUserResults.value = Right(
      ExceptionsSearchSuccessState(
        exceptionsMember: searchResults,
        keyword: searchTerm,
      ),
    );
  }

  @override
  void initState() {
    _powerLevelsSubscription = widget.room.powerLevelsChanged.listen((_) {
      initialExceptions();
    });
    initialExceptions();
    textEditingController.addListener(
      () => setDebouncerValue(textEditingController.text),
    );
    initializeDebouncer((searchTerm) {
      Logs().d("ExceptionsController::initState: $searchTerm");
      handleSearchResults(searchTerm);
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _powerLevelsSubscription?.cancel();
    textEditingController.dispose();
    inputFocus.dispose();
    searchUserResults.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ChatDetailEditViewStyle.fixedWidth,
      child: ExceptionsView(controller: this),
    );
  }
}
