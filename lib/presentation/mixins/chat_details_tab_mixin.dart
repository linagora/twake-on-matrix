import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/ban_user_state.dart';
import 'package:fluffychat/domain/app_state/room/set_permission_level_state.dart';
import 'package:fluffychat/domain/usecase/room/ban_user_interactor.dart';
import 'package:fluffychat/domain/usecase/room/set_permission_level_interactor.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/selected_user_notifier.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/assign_roles_role_picker.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/role_picker_type_enum.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_members_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_page_enum.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/links/chat_details_links_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/media/chat_details_media_page.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection_web.dart';
import 'package:fluffychat/presentation/enum/chat/chat_details_screen_enum.dart';
import 'package:fluffychat/presentation/extensions/event_update_extension.dart';
import 'package:fluffychat/presentation/extensions/room_summary_extension.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/chat_details/chat_details_page_model.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';

mixin ChatDetailsTabMixin<T extends StatefulWidget>
    on
        TickerProviderStateMixin<T>,
        HandleVideoDownloadMixin,
        PlayVideoActionMixin {
  final GlobalKey<NestedScrollViewState> nestedScrollViewState = GlobalKey();

  final responsive = getIt.get<ResponsiveUtils>();

  final banUserInteractor = getIt.get<BanUserInteractor>();

  StreamSubscription? _banUserSubscription;

  final ValueNotifier<List<User>?> _membersNotifier = ValueNotifier(null);

  final ValueNotifier<List<User>?> _displayMembersNotifier = ValueNotifier(
    null,
  );

  StreamSubscription? _powerLevelsSubscription;
  StreamSubscription? _setPermissionLevelSubscription;

  late final List<ChatDetailsPage> tabList;

  final removeUsersChangeNotifier = SelectedUsersMapChangeNotifier();

  Room? get room;

  ChatDetailsScreenEnum get chatType;

  int get actualMembersCount => room!.summary.actualMembersCount;

  bool get isMobileAndTablet =>
      responsive.isMobile(context) || responsive.isTablet(context);

  SameTypeEventsBuilderController? _mediaListController;
  SameTypeEventsBuilderController? _linksListController;
  SameTypeEventsBuilderController? _filesListController;
  TabController? tabController;

  Timeline? _timeline;

  StreamSubscription? _onRoomEventChangedSubscription;

  static const _mediaFetchLimit = 20;
  static const _linksFetchLimit = 20;
  static const _filesFetchLimit = 20;
  static const _membersPerPage = 30;
  int _currentMembersCount = _membersPerPage;

  static const _memberPageKey = PageStorageKey('members');
  static const _mediaPageKey = PageStorageKey('media');
  static const _linksPageKey = PageStorageKey('links');
  static const _filesPageKey = PageStorageKey('files');

  static const invitationSelectionMobileAndTabletKey = Key(
    'InvitationSelectionMobileAndTabletKey',
  );
  static const invitationSelectionWebAndDesktopKey = Key(
    'InvitationSelectionWebAndDesktopKey',
  );

  Future<Timeline?> _getTimeline() async {
    _timeline ??= await room?.getTimeline();
    return _timeline;
  }

  Future<Uint8List> _handleDownloadAndPlayVideo(Event event) {
    return handleDownloadVideoEvent(
      event: event,
      playVideoAction: (path) => playVideoAction(context, path, event: event),
    );
  }

  void _initTabList() {
    tabList = [
      if (chatType == ChatDetailsScreenEnum.group) ChatDetailsPage.members,
      ChatDetailsPage.media,
      ChatDetailsPage.links,
      ChatDetailsPage.files,
    ];
  }

  void _listenForRoomMembersChanged() {
    _onRoomEventChangedSubscription = Matrix.of(context).client.onEvent.stream
        .listen((event) {
          if (event.isMemberChangedEvent && room?.id == event.roomID) {
            _membersNotifier.value = room?.getParticipants().toList()
              ?..sort(
                (small, great) => great.powerLevel.compareTo(small.powerLevel),
              );
          }
        });
  }

  void _requestMoreMembersAction() async {
    final currentMembersCount = _displayMembersNotifier.value?.length ?? 0;
    final members = _membersNotifier.value;
    if (members == null || currentMembersCount >= members.length) return;

    if (_currentMembersCount < members.length) {
      _currentMembersCount += _membersPerPage;
    }

    final endIndex = min(_currentMembersCount, members.length);
    _displayMembersNotifier.value = members.sublist(0, endIndex);
  }

  void _initDisplayMembers() {
    final members = _membersNotifier.value;
    if (members != null && members.isNotEmpty) {
      final endIndex = _currentMembersCount > members.length
          ? members.length
          : _currentMembersCount;
      _displayMembersNotifier.value = members.sublist(0, endIndex);
    } else {
      _displayMembersNotifier.value = [];
    }
  }

  void _openDialogInvite() {
    if (PlatformInfos.isMobile) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => InvitationSelection(roomId: room!.id),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      useRootNavigator: !PlatformInfos.isMobile,
      builder: (context) {
        return SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            const WidthPlatformBreakpoint(
              begin: ResponsiveUtils.minDesktopWidth,
            ): SlotLayout.from(
              key: invitationSelectionWebAndDesktopKey,
              builder: (_) => InvitationSelectionWebView(roomId: room!.id),
            ),
            const WidthPlatformBreakpoint(
              end: ResponsiveUtils.minDesktopWidth,
            ): SlotLayout.from(
              key: invitationSelectionMobileAndTabletKey,
              builder: (_) => InvitationSelection(roomId: room!.id),
            ),
          },
        );
      },
    );
  }

  Future<void> onUpdateMembers() async {
    final members = room!.getParticipants([Membership.join, Membership.invite])
      ..sort((small, great) => great.powerLevel.compareTo(small.powerLevel));
    _membersNotifier.value = members;
    _displayMembersNotifier.value = members;
  }

  void _initControllers() {
    tabController = TabController(length: tabList.length, vsync: this);
    _mediaListController = SameTypeEventsBuilderController(
      getTimeline: () => _getTimeline(),
      searchFunc: (event) => event.isVideoOrImage,
      limit: _mediaFetchLimit,
    );
    _linksListController = SameTypeEventsBuilderController(
      getTimeline: () => _getTimeline(),
      searchFunc: (event) => event.isContainsLink,
      limit: _linksFetchLimit,
    );
    _filesListController = SameTypeEventsBuilderController(
      getTimeline: () => _getTimeline(),
      searchFunc: (event) => event.isAFile,
      limit: _filesFetchLimit,
    );
  }

  void _initMembers() {
    if (chatType == ChatDetailsScreenEnum.group) {
      _membersNotifier.value = room?.getParticipants().toList()
        ?..sort((small, great) => great.powerLevel.compareTo(small.powerLevel));
      _initDisplayMembers();
    }
  }

  void _listenerInnerController() {
    if (nestedScrollViewState.currentState?.innerController.shouldLoadMore ==
            true &&
        tabController?.index != null) {
      switch (tabList[tabController!.index]) {
        case ChatDetailsPage.media:
          _mediaListController?.loadMore();
          break;
        case ChatDetailsPage.links:
          _linksListController?.loadMore();
          break;
        case ChatDetailsPage.files:
          _filesListController?.loadMore();
          break;
        default:
          break;
      }
    }
  }

  void refreshDataInTabViewInit() {
    _linksListController?.refresh();
    _mediaListController?.refresh();
    _filesListController?.refresh();
  }

  void _disposeControllers() {
    _mediaListController?.dispose();
    _linksListController?.dispose();
    _filesListController?.dispose();
    tabController?.dispose();
  }

  void onTapAddMembers() {
    _openDialogInvite();
  }

  List<ChatDetailsPageModel> sharedPages() => tabList.map((page) {
    if (chatType == ChatDetailsScreenEnum.group &&
        page == ChatDetailsPage.members) {
      return ChatDetailsPageModel(
        page: page,
        child: ChatDetailsMembersPage(
          key: _memberPageKey,
          displayMembersNotifier: _displayMembersNotifier,
          actualMembersCount: actualMembersCount,
          requestMoreMembersAction: _requestMoreMembersAction,
          openDialogInvite: _openDialogInvite,
          isMobileAndTablet: isMobileAndTablet,
          onUpdatedMembers: () async => await onUpdateMembers(),
          selectedUsersMapChangeNotifier: removeUsersChangeNotifier,
          onSelectMember: _onSelectMember,
          onRemoveMember: _handleOnRemoveMember,
          onChangeRole: _handleChangePermission,
        ),
      );
    }
    switch (page) {
      case ChatDetailsPage.media:
        return ChatDetailsPageModel(
          page: page,
          child: _mediaListController == null
              ? const SizedBox()
              : ChatDetailsMediaPage(
                  key: _mediaPageKey,
                  controller: _mediaListController!,
                  handleDownloadVideoEvent: _handleDownloadAndPlayVideo,
                  // closeRightColumn: widget.closeRightColumn,
                ),
        );
      case ChatDetailsPage.links:
        return ChatDetailsPageModel(
          page: page,
          child: _linksListController == null
              ? const SizedBox()
              : ChatDetailsLinksPage(
                  key: _linksPageKey,
                  controller: _linksListController!,
                ),
        );
      case ChatDetailsPage.files:
        return ChatDetailsPageModel(
          page: page,
          child: _filesListController == null
              ? const SizedBox()
              : ChatDetailsFilesPage(
                  key: _filesPageKey,
                  controller: _filesListController!,
                ),
        );
      default:
        return ChatDetailsPageModel(page: page, child: const SizedBox());
    }
  }).toList();

  void _onSelectMember(User user) {
    if (!PlatformInfos.isMobile) return;

    if (!user.canBan) {
      TwakeSnackBar.show(context, L10n.of(context)!.removeMemberSelectionError);
      return;
    }

    removeUsersChangeNotifier.onUserTileTap(context, user);
  }

  void _handleOnRemoveMember(User user) {
    if (room == null) return;
    _banUserSubscription = banUserInteractor
        .execute(user: user, room: room!)
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

  void _handleChangePermission(User user, {DefaultPowerLevelMember? role}) {
    if (room == null) return;

    if (role != null) {
      _setPermission(user, role);
    } else if (PlatformInfos.isWeb) {
      _openAssignRolesPageForWeb(user);
    } else {
      _openAssignRolesPageForMobile(user);
    }
  }

  void _setPermission(User user, DefaultPowerLevelMember role) {
    _setPermissionLevelSubscription?.cancel();
    _setPermissionLevelSubscription = getIt
        .get<SetPermissionLevelInteractor>()
        .execute(room: room!, userPermissionLevels: {user: role.powerLevel})
        .listen(
          (either) async => await either.fold(
            (failure) async => _handleSetPermissionFailure(failure),
            (success) async => await _handleSetPermissionSuccess(success),
          ),
          onError: (error) {
            Logs().e('SetPermissionLevel error', error);
            TwakeDialog.hideLoadingDialog(context);
            TwakeSnackBar.show(context, error.toString());
          },
          onDone: () => _setPermissionLevelSubscription?.cancel(),
        );
  }

  void _handleSetPermissionFailure(Failure failure) {
    TwakeDialog.hideLoadingDialog(context);

    if (failure is SetPermissionLevelFailure) {
      TwakeSnackBar.show(context, failure.exception.toString());
      return;
    }

    if (failure is NoPermissionFailure) {
      TwakeSnackBar.show(context, L10n.of(context)!.permissionErrorChangeRole);
      return;
    }
  }

  Future<void> _handleSetPermissionSuccess(Success success) async {
    if (success is SetPermissionLevelLoading) {
      TwakeDialog.showLoadingDialog(context);
      return;
    }

    try {
      await onUpdateMembers();
    } catch (e) {
      Logs().e('_handleSetPermissionSuccess() - error: $e');
    } finally {
      TwakeDialog.hideLoadingDialog(context);
    }
  }

  /// Opens assign roles role picker page for web platform
  Future<void> _openAssignRolesPageForWeb(User user) async {
    if (room == null) return;
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (_) => ScaffoldMessenger(
        child: Builder(
          builder: (messengerContext) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16.0)),
              ),
              contentPadding: const EdgeInsets.all(0),
              content: SizedBox(
                width: min(
                  600,
                  MediaQuery.of(messengerContext).size.width * 0.9,
                ),
                height: min(
                  700,
                  MediaQuery.of(messengerContext).size.height * 0.9,
                ),
                child: AssignRolesRolePicker(
                  room: room!,
                  assignedUsers: [user],
                  isDialog: true,
                  rolePickerType: RolePickerTypeEnum.all,
                  onSuccess: () => Navigator.pop(messengerContext),
                ),
              ),
            );
          },
        ),
      ),
    );
    await onUpdateMembers();
  }

  /// Opens assign roles role picker page for mobile platform
  Future<void> _openAssignRolesPageForMobile(User user) async {
    if (room == null) return;
    await Navigator.of(context).push(
      CupertinoPageRoute(
        settings: const RouteSettings(name: '/assign_roles_role_picker'),
        builder: (context) {
          return AssignRolesRolePicker(
            room: room!,
            assignedUsers: [user],
            rolePickerType: RolePickerTypeEnum.all,
            onSuccess: () => Navigator.pop(context),
          );
        },
      ),
    );
    await onUpdateMembers();
  }

  @override
  void initState() {
    super.initState();
    _initTabList();
    _initMembers();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _powerLevelsSubscription = room?.powerLevelsChanged.listen((event) {
        _initMembers();
      });
      nestedScrollViewState.currentState?.innerController.addListener(
        () => _listenerInnerController(),
      );
      refreshDataInTabViewInit();
    });
    _listenForRoomMembersChanged();
  }

  @override
  void dispose() {
    _disposeControllers();
    _membersNotifier.dispose();
    _displayMembersNotifier.dispose();
    _onRoomEventChangedSubscription?.cancel();
    nestedScrollViewState.currentState?.innerController.dispose();
    _powerLevelsSubscription?.cancel();
    removeUsersChangeNotifier.dispose();
    _banUserSubscription?.cancel();
    _setPermissionLevelSubscription?.cancel();
    super.dispose();
  }
}
