import 'dart:async';
import 'package:fluffychat/di/global/get_it_initializer.dart';
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
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:matrix/matrix.dart';

mixin ChatDetailsTabMixin<T extends StatefulWidget>
    on
        SingleTickerProviderStateMixin<T>,
        HandleVideoDownloadMixin,
        PlayVideoActionMixin {
  final GlobalKey<NestedScrollViewState> nestedScrollViewState = GlobalKey();

  final responsive = getIt.get<ResponsiveUtils>();

  final ValueNotifier<List<User>?> _membersNotifier = ValueNotifier(null);

  late final List<ChatDetailsPage> tabList;

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

  static const _memberPageKey = PageStorageKey('members');
  static const _mediaPageKey = PageStorageKey('media');
  static const _linksPageKey = PageStorageKey('links');
  static const _filesPageKey = PageStorageKey('files');

  static const invitationSelectionMobileAndTabletKey =
      Key('InvitationSelectionMobileAndTabletKey');
  static const invitationSelectionWebAndDesktopKey =
      Key('InvitationSelectionWebAndDesktopKey');

  Future<Timeline> _getTimeline() async {
    _timeline ??= await room!.getTimeline();
    return _timeline!;
  }

  Future<String> _handleDownloadAndPlayVideo(Event event) {
    return handleDownloadVideoEvent(
      event: event,
      playVideoAction: (path) => playVideoAction(
        context,
        path,
        event: event,
      ),
    );
  }

  void _initTabList() {
    if (room != null) {
      tabList = [
        if (chatType == ChatDetailsScreenEnum.group) ChatDetailsPage.members,
        ChatDetailsPage.media,
        ChatDetailsPage.links,
        ChatDetailsPage.files,
      ];
    } else {
      tabList = [];
    }
  }

  void _listenForRoomMembersChanged() {
    _onRoomEventChangedSubscription =
        Matrix.of(context).client.onEvent.stream.listen((event) {
      if (event.isMemberChangedEvent && room?.id == event.roomID) {
        _membersNotifier.value = room?.getParticipants();
      }
    });
  }

  void _requestMoreMembersAction() async {
    final participants = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => room!.requestParticipants(),
    );
    if (participants.error == null) {
      _membersNotifier.value = participants.result;
    }
  }

  void _openDialogInvite() {
    if (PlatformInfos.isMobile) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => InvitationSelection(
            roomId: room!.id,
          ),
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
              builder: (_) => InvitationSelectionWebView(
                roomId: room!.id,
              ),
            ),
            const WidthPlatformBreakpoint(
              end: ResponsiveUtils.minDesktopWidth,
            ): SlotLayout.from(
              key: invitationSelectionMobileAndTabletKey,
              builder: (_) => InvitationSelection(
                roomId: room!.id,
              ),
            ),
          },
        );
      },
    );
  }

  Future<void> _onUpdateMembers() async {
    final members = await room!.requestParticipantsFromServer();
    _membersNotifier.value = members;
  }

  void _initControllers() {
    tabController = TabController(
      length: tabList.length,
      vsync: this,
    );
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
      _membersNotifier.value ??= room?.getParticipants();
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

  void _refreshDataInTabViewInit() {
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

  List<ChatDetailsPageModel> sharedPages() => tabList.map(
        (page) {
          if (chatType == ChatDetailsScreenEnum.group &&
              page == ChatDetailsPage.members) {
            return ChatDetailsPageModel(
              page: page,
              child: ChatDetailsMembersPage(
                key: _memberPageKey,
                membersNotifier: _membersNotifier,
                actualMembersCount: actualMembersCount,
                canRequestMoreMembers:
                    (_membersNotifier.value?.length ?? 0) < actualMembersCount,
                requestMoreMembersAction: _requestMoreMembersAction,
                openDialogInvite: _openDialogInvite,
                isMobileAndTablet: isMobileAndTablet,
                onUpdatedMembers: _onUpdateMembers,
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
              return ChatDetailsPageModel(
                page: page,
                child: const SizedBox(),
              );
          }
        },
      ).toList();

  @override
  void initState() {
    super.initState();
    _initTabList();
    _initMembers();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nestedScrollViewState.currentState?.innerController.addListener(
        () => _listenerInnerController(),
      );
      _refreshDataInTabViewInit();
    });
    _listenForRoomMembersChanged();
  }

  @override
  void dispose() {
    _disposeControllers();
    _membersNotifier.dispose();
    _onRoomEventChangedSubscription?.cancel();
    nestedScrollViewState.currentState?.innerController.dispose();
    super.dispose();
  }
}
