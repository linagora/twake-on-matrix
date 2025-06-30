import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_editor/assign_roles_editor.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_picker/assign_roles_picker_search_state.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_picker/assign_roles_picker_view.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_picker/selected_user_notifier.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix.dart';

class AssignRolesPicker extends StatefulWidget {
  final Room room;

  const AssignRolesPicker({
    super.key,
    required this.room,
  });

  @override
  AssignRolesPickerController createState() => AssignRolesPickerController();
}

class AssignRolesPickerController extends State<AssignRolesPicker>
    with SearchDebouncerMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  final SelectedUsersMapChangeNotifier selectedUsersMapChangeNotifier =
      SelectedUsersMapChangeNotifier();

  final ValueNotifier<Either<Failure, Success>> searchUserResults =
      ValueNotifier<Either<Failure, Success>>(
    Right(
      AssignRolesPickerSearchInitialState(),
    ),
  );

  List<User> get members => widget.room.getCurrentMembers();

  void initialAssignRoles() {
    searchUserResults.value = Right(
      AssignRolesPickerSearchSuccessState(
        members: members,
        keyword: '',
      ),
    );
  }

  void handleSearchResults(String searchTerm) {
    if (searchTerm.isEmpty) {
      searchUserResults.value = Right(
        AssignRolesPickerSearchSuccessState(
          members: members,
          keyword: '',
        ),
      );
      return;
    }

    final assignedUsers = members;

    final searchResults = assignedUsers.where((user) {
      return (user.displayName ?? '')
              .toLowerCase()
              .contains(searchTerm.toLowerCase()) ||
          (user.id).toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();

    Logs().d(
      "AssignRolesController::handleSearchResults: $searchTerm, results: ${searchResults.length}",
    );

    if (searchResults.isEmpty) {
      searchUserResults.value = Left(
        AssignRolesPickerSearchEmptyState(keyword: searchTerm),
      );
      return;
    }

    searchUserResults.value = Right(
      AssignRolesPickerSearchSuccessState(
        members: searchResults,
        keyword: searchTerm,
      ),
    );
  }

  void navigateToAssignRolesEditor(BuildContext context) {
    if (selectedUsersMapChangeNotifier.usersList.isEmpty) {
      return;
    }

    if (responsive.isMobile(context)) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) {
            return AssignRolesEditor(
              room: widget.room,
              assignedUsers: selectedUsersMapChangeNotifier.usersList.toList(),
            );
          },
        ),
      );
      return;
    }
  }

  @override
  void initState() {
    initialAssignRoles();
    textEditingController.addListener(
      () => setDebouncerValue(textEditingController.text),
    );
    initializeDebouncer((searchTerm) {
      Logs().d("AssignRolesController::initState: $searchTerm");
      handleSearchResults(searchTerm);
    });
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    inputFocus.dispose();
    searchUserResults.dispose();
    selectedUsersMapChangeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AssignRolesPickerView(
      controller: this,
    );
  }
}
