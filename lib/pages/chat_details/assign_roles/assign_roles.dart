import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/ban_user_state.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/usecase/room/ban_user_interactor.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles_search_state.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles_view.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker_style.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/selected_user_notifier.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/quick_role_picker_mixin.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view_style.dart';
import 'package:fluffychat/pages/chat_list/chat_custom_slidable_action.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class AssignRoles extends StatefulWidget {
  final Room room;

  const AssignRoles({super.key, required this.room});

  @override
  AssignRolesController createState() => AssignRolesController();
}

class AssignRolesController extends State<AssignRoles>
    with SearchDebouncerMixin, TwakeContextMenuMixin, QuickRolePickerMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  final banUserInteractor = getIt.get<BanUserInteractor>();

  StreamSubscription? _powerLevelsSubscription;

  StreamSubscription? _banUserSubscription;

  final SelectedUsersMapChangeNotifier selectedUsersMapChangeNotifier =
      SelectedUsersMapChangeNotifier();

  final ValueNotifier<bool> enableSelectMembersMobileNotifier =
      ValueNotifier<bool>(false);

  final ValueNotifier<List<User>> membersNotifier = ValueNotifier<List<User>>(
    [],
  );

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  final ValueNotifier<Either<Failure, Success>> searchUserResults =
      ValueNotifier<Either<Failure, Success>>(
        Right(AssignRolesSearchInitialState()),
      );

  void onBack() {
    Navigator.of(context).pop();
  }

  void goToAssignRolesPicker() {
    if (responsive.isMobile(context)) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          settings: const RouteSettings(name: '/assign-roles-member-picker'),
          builder: (context) {
            return AssignRolesMemberPicker(room: widget.room);
          },
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (dialogContext) => ScaffoldMessenger(
        child: AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: SizedBox(
            width: AssignRolesMemberPickerStyle.fixedDialogWidth,
            height: AssignRolesMemberPickerStyle.fixedDialogHeight,
            child: AssignRolesMemberPicker(room: widget.room, isDialog: true),
          ),
        ),
      ),
    );
  }

  List<User> get assignRolesMember => widget.room.getAssignRolesMember();

  void initialAssignRoles() {
    membersNotifier.value = assignRolesMember;
    searchUserResults.value = Right(
      AssignRolesSearchSuccessState(
        assignRolesMember: assignRolesMember,
        keyword: '',
      ),
    );
  }

  void handleSearchResults(String searchTerm) {
    if (searchTerm.isEmpty) {
      searchUserResults.value = Right(
        AssignRolesSearchSuccessState(
          assignRolesMember: assignRolesMember,
          keyword: '',
        ),
      );
      return;
    }

    final assignedUsers = assignRolesMember;

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
        AssignRolesSearchEmptyState(keyword: searchTerm),
      );
      return;
    }

    searchUserResults.value = Right(
      AssignRolesSearchSuccessState(
        assignRolesMember: searchResults,
        keyword: searchTerm,
      ),
    );
  }

  void _listenToSelectedUsersMapChange() {
    selectedUsersMapChangeNotifier.addListener(() {
      Logs().d(
        "AssignRolesController::initState: selectedUsersMapChangeNotifier: ${selectedUsersMapChangeNotifier.usersList.length}",
      );
      if (responsive.isMobile(context)) {
        enableSelectMembersMobileNotifier.value =
            selectedUsersMapChangeNotifier.usersList.isNotEmpty;
      }
    });
  }

  void handleOnLongPressMobile({required User member}) {
    if (!responsive.isMobile(context)) {
      return;
    }

    if (!widget.room.canAssignRoles) {
      return;
    }

    if (!widget.room.canUpdateRoleInRoom(member)) {
      return;
    }

    enableSelectMembersMobileNotifier.toggle();
    selectedUsersMapChangeNotifier.onUserTileTap(context, member);
  }

  void handleDemoteMultiAdminsAndModeratorsMobile() {
    if (!responsive.isMobile(context)) {
      return;
    }
    if (!widget.room.canAssignRoles) {
      return;
    }
    if (selectedUsersMapChangeNotifier.usersList.isEmpty) {
      return;
    }

    handleClickOnContextMenuItem(
      userPermissionLevels: {
        for (final user in selectedUsersMapChangeNotifier.usersList)
          user: DefaultPowerLevelMember.member.powerLevel,
      },
      context,
      room: widget.room,
      onHandledResult: selectedUsersMapChangeNotifier.unselectAllUsers,
    );
  }

  List<Widget> getSlidables({
    required BuildContext context,
    required User user,
  }) {
    return [
      if (widget.room.canUpdateRoleInRoom(user))
        ChatCustomSlidableAction(
          label: L10n.of(context)!.downgrade,
          icon: Icon(
            Icons.admin_panel_settings_outlined,
            color: LinagoraSysColors.material().onPrimary,
          ),
          onPressed: (_) => handleClickOnContextMenuItem(
            userPermissionLevels: {
              user: DefaultPowerLevelMember.member.powerLevel,
            },
            context,
            room: widget.room,
            onHandledResult: selectedUsersMapChangeNotifier.unselectAllUsers,
          ),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor: const Color(0xFF8F9498),
        ),
      if (widget.room.canBanMemberInRoom(user))
        ChatCustomSlidableAction(
          label: L10n.of(context)!.remove,
          icon: Icon(
            Icons.person_remove_outlined,
            color: LinagoraSysColors.material().onPrimary,
          ),
          onPressed: (_) => _handleOnTapRemoveUser(user: user),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor: LinagoraSysColors.material().error,
        ),
    ];
  }

  void _handleOnTapRemoveUser({required User user}) {
    _banUserSubscription = banUserInteractor
        .execute(user: user, room: widget.room)
        .listen((result) {
          result.fold(
            (failure) {
              if (failure is BanUserFailure) {
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(context, failure.exception.toString());
                return;
              }

              if (failure is NoPermissionForBanFailure) {
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.permissionErrorBanUser,
                );
                return;
              }
            },
            (success) async {
              if (success is BanUserLoading) {
                TwakeDialog.showLoadingDialog(context);
                return;
              }

              if (success is BanUserSuccess) {
                TwakeDialog.hideLoadingDialog(context);
                return;
              }
            },
          );
        });
  }

  @override
  void initState() {
    _powerLevelsSubscription = widget.room.powerLevelsChanged.listen((event) {
      Logs().d(
        "AssignRolesController::initState: powerLevelsChanged event: $event",
      );
      initialAssignRoles();
    });
    initialAssignRoles();
    textEditingController.addListener(
      () => setDebouncerValue(textEditingController.text),
    );
    _listenToSelectedUsersMapChange();
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
    membersNotifier.dispose();
    searchUserResults.dispose();
    _powerLevelsSubscription?.cancel();
    disposeDebouncer();
    selectedUsersMapChangeNotifier.dispose();
    enableSelectMembersMobileNotifier.dispose();
    _banUserSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ChatDetailEditViewStyle.fixedWidth,
      child: AssignRolesView(controller: this),
    );
  }
}
