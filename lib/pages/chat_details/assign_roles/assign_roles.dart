import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/ban_user_state.dart';
import 'package:fluffychat/domain/app_state/room/set_permission_level_state.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/usecase/room/ban_user_interactor.dart';
import 'package:fluffychat/domain/usecase/room/set_permission_level_interactor.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles_search_state.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles_view.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker_style.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/selected_user_notifier.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view_style.dart';
import 'package:fluffychat/pages/chat_list/chat_custom_slidable_action.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AssignRoles extends StatefulWidget {
  final Room room;

  const AssignRoles({
    super.key,
    required this.room,
  });

  @override
  AssignRolesController createState() => AssignRolesController();
}

class AssignRolesController extends State<AssignRoles>
    with SearchDebouncerMixin, TwakeContextMenuMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  final setPermissionLevelInteractor =
      getIt.get<SetPermissionLevelInteractor>();

  final banUserInteractor = getIt.get<BanUserInteractor>();

  StreamSubscription? _setPermissionLevelSubscription;

  StreamSubscription? _powerLevelsSubscription;

  StreamSubscription? _banUserSubscription;

  final SelectedUsersMapChangeNotifier selectedUsersMapChangeNotifier =
      SelectedUsersMapChangeNotifier();

  final ValueNotifier<bool> enableSelectMembersMobileNotifier =
      ValueNotifier<bool>(false);

  final ValueNotifier<List<User>> membersNotifier =
      ValueNotifier<List<User>>([]);

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  final ValueNotifier<Either<Failure, Success>> searchUserResults =
      ValueNotifier<Either<Failure, Success>>(
    Right(
      AssignRolesSearchInitialState(),
    ),
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
            return AssignRolesMemberPicker(
              room: widget.room,
            );
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
            borderRadius: BorderRadius.all(
              Radius.circular(16.0),
            ),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: SizedBox(
            width: AssignRolesMemberPickerStyle.fixedDialogWidth,
            height: AssignRolesMemberPickerStyle.fixedDialogHeight,
            child: AssignRolesMemberPicker(
              room: widget.room,
              isDialog: true,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> handleOnTapQuickRolePickerMobile({
    required BuildContext context,
    required User user,
  }) async {
    if (!widget.room.canUpdateRoleInRoom(user)) {
      return;
    }
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        width: double.infinity,
        padding: MediaQuery.viewInsetsOf(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.3,
          maxChildSize: 0.5,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 12,
              ),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    width: 32,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: LinagoraSysColors.material().outline,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: quickRolePicker
                          .map(
                            (role) => _quickRolePickerItem(
                              context: context,
                              role: role,
                              user: user,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _quickRolePickerItem({
    required BuildContext context,
    required DefaultPowerLevelMember role,
    required User user,
  }) {
    return InkWell(
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: () {
        Navigator.of(context).pop();
        _handleClickOnContextMenuItem(
          userPermissionLevels: {
            user: role.powerLevel,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        height: 36,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                role.displayName(context),
                style: context.textTheme.bodyLarge?.copyWith(
                  color: LinagoraSysColors.material().onSurface,
                ),
              ),
            ),
            if (role.powerLevel == user.powerLevel)
              SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.check,
                  color: LinagoraSysColors.material().onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> handleOnTapQuickRolePickerWeb({
    required BuildContext context,
    required TapDownDetails tapDownDetails,
    required User user,
  }) async {
    if (!widget.room.canUpdateRoleInRoom(user)) {
      return;
    }
    final offset = tapDownDetails.globalPosition;

    final selectedActionIndex = await showTwakeContextMenu(
      offset: offset,
      context: context,
      listActions: _mapPopupRolesToContextMenuActions(
        user: user,
      ),
    );

    if (selectedActionIndex != null && selectedActionIndex is int) {
      _handleClickOnContextMenuItem(
        userPermissionLevels: {
          user: quickRolePicker[selectedActionIndex].powerLevel,
        },
      );
    }
  }

  void _handleClickOnContextMenuItem({
    required Map<User, int> userPermissionLevels,
  }) {
    _setPermissionLevelSubscription = setPermissionLevelInteractor
        .execute(room: widget.room, userPermissionLevels: userPermissionLevels)
        .listen((result) {
      _handleAssignRolesResult(result);
    });
  }

  void _handleAssignRolesResult(Either<Failure, Success> result) {
    result.fold(
      (failure) {
        if (failure is SetPermissionLevelFailure) {
          TwakeDialog.hideLoadingDialog(context);
          TwakeSnackBar.show(
            context,
            failure.exception.toString(),
          );
          selectedUsersMapChangeNotifier.unselectAllUsers();
          return;
        }

        if (failure is NoPermissionFailure) {
          TwakeDialog.hideLoadingDialog(context);
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.permissionErrorChangeRole,
          );
          selectedUsersMapChangeNotifier.unselectAllUsers();
          return;
        }
      },
      (success) {
        if (success is SetPermissionLevelLoading) {
          TwakeDialog.showLoadingDialog(context);
          selectedUsersMapChangeNotifier.unselectAllUsers();
          return;
        }

        if (success is SetPermissionLevelSuccess) {
          TwakeDialog.hideLoadingDialog(context);
          selectedUsersMapChangeNotifier.unselectAllUsers();

          return;
        }
      },
    );
  }

  List<ContextMenuAction> _mapPopupRolesToContextMenuActions({
    required User user,
  }) {
    return quickRolePicker.map((action) {
      return ContextMenuAction(
        name: action.displayName(context),
        icon: action.powerLevel == user.powerLevel ? Icons.check : null,
        colorIcon: LinagoraRefColors.material().neutral[30],
      );
    }).toList();
  }

  final List<DefaultPowerLevelMember> quickRolePicker = [
    DefaultPowerLevelMember.admin,
    DefaultPowerLevelMember.moderator,
    DefaultPowerLevelMember.member,
    DefaultPowerLevelMember.guest,
  ];

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

  void handleOnLongPressMobile({
    required User member,
  }) {
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
    selectedUsersMapChangeNotifier.onUserTileTap(
      context,
      member,
    );
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

    _handleClickOnContextMenuItem(
      userPermissionLevels: {
        for (final user in selectedUsersMapChangeNotifier.usersList)
          user: DefaultPowerLevelMember.member.powerLevel,
      },
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
          onPressed: (_) => _handleClickOnContextMenuItem(
            userPermissionLevels: {
              user: DefaultPowerLevelMember.member.powerLevel,
            },
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

  void _handleOnTapRemoveUser({
    required User user,
  }) {
    _banUserSubscription =
        banUserInteractor.execute(user: user).listen((result) {
      result.fold(
        (failure) {
          if (failure is BanUserFailure) {
            TwakeDialog.hideLoadingDialog(context);
            TwakeSnackBar.show(
              context,
              failure.exception.toString(),
            );
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
    _setPermissionLevelSubscription?.cancel();
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
      child: AssignRolesView(
        controller: this,
      ),
    );
  }
}
