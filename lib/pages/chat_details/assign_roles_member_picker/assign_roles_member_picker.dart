import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/assign_roles_role_picker.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/assign_roles_role_picker_style.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker_search_state.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker_view.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/selected_user_notifier.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/role_picker_type_enum.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class AssignRolesMemberPicker extends StatefulWidget {
  final Room room;
  final bool isDialog;

  const AssignRolesMemberPicker({
    super.key,
    required this.room,
    this.isDialog = false,
  });

  @override
  AssignRolesPickerController createState() => AssignRolesPickerController();
}

class AssignRolesPickerController extends State<AssignRolesMemberPicker>
    with SearchDebouncerMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  final SelectedUsersMapChangeNotifier selectedUsersMapChangeNotifier =
      SelectedUsersMapChangeNotifier();

  final ValueNotifier<Either<Failure, Success>> searchUserResults =
      ValueNotifier<Either<Failure, Success>>(
        Right(AssignRolesMemberPickerSearchInitialState()),
      );

  List<User> get members => widget.room.getCurrentMembers().where((member) {
    return widget.room.canUpdateRoleInRoom(member);
  }).toList();

  void initialAssignRoles() {
    searchUserResults.value = Right(
      AssignRolesMemberPickerSearchSuccessState(members: members, keyword: ''),
    );
  }

  void handleSearchResults(String searchTerm) {
    if (searchTerm.isEmpty) {
      searchUserResults.value = Right(
        AssignRolesMemberPickerSearchSuccessState(
          members: members,
          keyword: '',
        ),
      );
      return;
    }

    final assignedUsers = members;

    final searchResults = assignedUsers.where((user) {
      return (user.displayName ?? '').toLowerCase().contains(
            searchTerm.toLowerCase(),
          ) ||
          (user.id).toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();

    Logs().d(
      "AssignRolesController::handleSearchResults: $searchTerm, results: ${searchResults.length}",
    );

    if (searchResults.isEmpty) {
      searchUserResults.value = Left(
        AssignRolesMemberPickerSearchEmptyState(keyword: searchTerm),
      );
      return;
    }

    searchUserResults.value = Right(
      AssignRolesMemberPickerSearchSuccessState(
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
          settings: const RouteSettings(name: '/assign_roles_role_picker'),
          builder: (context) {
            return AssignRolesRolePicker(
              room: widget.room,
              assignedUsers: selectedUsersMapChangeNotifier.usersList.toList(),
              rolePickerType: RolePickerTypeEnum.addAdminOrModerator,
            );
          },
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => ScaffoldMessenger(
        child: AlertDialog(
          contentPadding: const EdgeInsets.all(0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          content: SizedBox(
            width: AssignRolesRolePickerStyle.fixedDialogWidth,
            height: AssignRolesRolePickerStyle.fixedDialogHeight,
            child: AssignRolesRolePicker(
              room: widget.room,
              assignedUsers: selectedUsersMapChangeNotifier.usersList.toList(),
              isDialog: true,
              rolePickerType: RolePickerTypeEnum.addAdminOrModerator,
            ),
          ),
        ),
      ),
    );
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
    return Material(
      color: LinagoraSysColors.material().onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
      child: AssignRolesMemberPickerView(
        controller: this,
        isDialog: widget.isDialog,
      ),
    );
  }
}
