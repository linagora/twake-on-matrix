import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/set_permission_level_state.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/usecase/room/set_permission_level_interactor.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles_search_state.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles_view.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker_style.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view_style.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
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

  StreamSubscription? _powerLevelsSubscription;

  final ValueNotifier<List<User>> membersNotifier =
      ValueNotifier<List<User>>([]);

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  Stream get powerLevelsChanged => widget.room.client.onSync.stream.where(
        (e) =>
            (e.rooms?.join?.containsKey(widget.room.id) ?? false) &&
            (e.rooms!.join![widget.room.id]?.timeline?.events
                    ?.any((s) => s.type == EventTypes.RoomPowerLevels) ??
                false),
      );

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
      builder: (dialogContext) => AlertDialog(
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
    );
  }

  void handleOnTapQuickRolePicker({
    required BuildContext context,
    required TapDownDetails tapDownDetails,
    required User user,
  }) async {
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
        role: quickRolePicker[selectedActionIndex],
        user: user,
      );
    }
  }

  void _handleClickOnContextMenuItem({
    required DefaultPowerLevelMember role,
    required User user,
  }) {
    setPermissionLevelInteractor.execute(
      userPermissionLevels: {
        user: role.powerLevel,
      },
    ).listen((result) {
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
          return;
        }

        if (failure is NoPermissionFailure) {
          TwakeDialog.hideLoadingDialog(context);
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.permissionErrorChangeRole,
          );
          return;
        }
      },
      (success) {
        if (success is SetPermissionLevelLoading) {
          TwakeDialog.showLoadingDialog(context);
          return;
        }

        if (success is SetPermissionLevelSuccess) {
          TwakeDialog.hideLoadingDialog(context);

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

  @override
  void initState() {
    _powerLevelsSubscription = powerLevelsChanged.listen((event) {
      Logs().d(
        "AssignRolesController::initState: powerLevelsChanged event: $event",
      );
      initialAssignRoles();
    });
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
    membersNotifier.dispose();
    searchUserResults.dispose();
    _powerLevelsSubscription?.cancel();
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
