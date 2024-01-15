import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_members_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_page_enum.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/links/chat_details_links_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/media/chat_details_media_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection_web.dart';
import 'package:fluffychat/presentation/extensions/room_summary_extension.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/chat_details/chat_details_page_model.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat_details/chat_details_view.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';

enum AliasActions { copy, delete, setCanonical }

class ChatDetails extends StatefulWidget {
  final String roomId;
  final bool isInStack;
  final VoidCallback? onBack;

  const ChatDetails({
    super.key,
    required this.roomId,
    required this.isInStack,
    this.onBack,
  });

  @override
  ChatDetailsController createState() => ChatDetailsController();
}

class ChatDetailsController extends State<ChatDetails>
    with
        HandleVideoDownloadMixin,
        PlayVideoActionMixin,
        SingleTickerProviderStateMixin {
  static const _mediaFetchLimit = 20;

  static const _linksFetchLimit = 20;

  final invitationSelectionMobileAndTabletKey =
      const Key('InvitationSelectionMobileAndTabletKey');

  final invitationSelectionWebAndDesktopKey =
      const Key('InvitationSelectionWebAndDesktopKey');

  final actionsMobileAndTabletKey = const Key('ActionsMobileAndTabletKey');

  final actionsWebAndDesktopKey = const Key('ActionsWebAndDesktopKey');

  final GlobalKey<NestedScrollViewState> nestedScrollViewState = GlobalKey();

  final List<ChatDetailsPage> chatDetailsPageView = [
    ChatDetailsPage.members,
    ChatDetailsPage.media,
    ChatDetailsPage.links,
  ];

  final responsive = getIt.get<ResponsiveUtils>();

  final Map<EventId, ImageData> _mediaCacheMap = {};

  final muteNotifier = ValueNotifier<PushRuleState>(
    PushRuleState.notify,
  );

  SameTypeEventsBuilderController? mediaListController;
  SameTypeEventsBuilderController? linksListController;

  Room? room;

  TabController? tabController;

  ValueNotifier<List<User>?> membersNotifier = ValueNotifier(null);

  String? get roomId => widget.roomId;

  bool get isMobileAndTablet =>
      responsive.isMobile(context) || responsive.isTablet(context);

  Timeline? _timeline;

  Future<Timeline> getTimeline() async {
    _timeline ??= await room!.getTimeline();
    return _timeline!;
  }

  int get actualMembersCount => room!.summary.actualMembersCount;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: chatDetailsPageView.length,
      vsync: this,
    );
    mediaListController = SameTypeEventsBuilderController(
      getTimeline: getTimeline,
      searchFunc: (event) => event.isVideoOrImage,
      limit: _mediaFetchLimit,
    );
    linksListController = SameTypeEventsBuilderController(
      getTimeline: getTimeline,
      searchFunc: (event) => event.isContainsLink,
      limit: _linksFetchLimit,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nestedScrollViewState.currentState?.innerController.addListener(
        _listenerInnerController,
      );
      _refreshDataInTabviewInit();
    });
    room = Matrix.of(context).client.getRoomById(roomId!);
    muteNotifier.value = room?.pushRuleState ?? PushRuleState.notify;
    membersNotifier.value ??=
        Matrix.of(context).client.getRoomById(roomId!)!.getParticipants();
  }

  @override
  void dispose() {
    tabController?.dispose();
    muteNotifier.dispose();
    mediaListController?.dispose();
    linksListController?.dispose();
    nestedScrollViewState.currentState?.innerController.dispose();
    super.dispose();
  }

  void _listenerInnerController() {
    Logs().d("ChatDetails::currentTab - ${tabController?.index}");
    if (nestedScrollViewState.currentState?.innerController.shouldLoadMore ==
            true &&
        tabController?.index != null) {
      switch (chatDetailsPageView[tabController!.index]) {
        case ChatDetailsPage.media:
          mediaListController?.loadMore();
          break;
        case ChatDetailsPage.links:
          linksListController?.loadMore();
          break;
        default:
          break;
      }
    }
  }

  void _refreshDataInTabviewInit() {
    linksListController?.refresh();
    mediaListController?.refresh();
  }

  void requestMoreMembersAction() async {
    final room = Matrix.of(context).client.getRoomById(roomId!);
    final participants = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => room!.requestParticipants(),
    );
    if (participants.error == null) {
      membersNotifier.value = participants.result;
    }
  }

  void openDialogInvite() {
    if (PlatformInfos.isMobile) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => InvitationSelection(
            roomId: roomId!,
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
                roomId: roomId!,
              ),
            ),
            const WidthPlatformBreakpoint(
              end: ResponsiveUtils.minDesktopWidth,
            ): SlotLayout.from(
              key: invitationSelectionMobileAndTabletKey,
              builder: (_) => InvitationSelection(
                roomId: roomId!,
              ),
            ),
          },
        );
      },
    );
  }

  Future<void> onUpdateMembers() async {
    final members = await room!.requestParticipantsFromServer();
    membersNotifier.value = members;
  }

  List<ChatDetailsPageModel> chatDetailsPages() => chatDetailsPageView.map(
        (page) {
          switch (page) {
            case ChatDetailsPage.members:
              return ChatDetailsPageModel(
                page: page,
                child: ChatDetailsMembersPage(
                  key: const PageStorageKey("members"),
                  membersNotifier: membersNotifier,
                  actualMembersCount: actualMembersCount,
                  canRequestMoreMembers:
                      (membersNotifier.value?.length ?? 0) < actualMembersCount,
                  requestMoreMembersAction: requestMoreMembersAction,
                  openDialogInvite: openDialogInvite,
                  isMobileAndTablet: isMobileAndTablet,
                  onUpdatedMembers: onUpdateMembers,
                ),
              );
            case ChatDetailsPage.media:
              return ChatDetailsPageModel(
                page: page,
                child: mediaListController == null
                    ? const SizedBox()
                    : ChatDetailsMediaPage(
                        key: const PageStorageKey<String>('Media'),
                        controller: mediaListController!,
                        cacheMap: _mediaCacheMap,
                        handleDownloadVideoEvent: _handleDownloadAndPlayVideo,
                      ),
              );
            case ChatDetailsPage.links:
              return ChatDetailsPageModel(
                page: page,
                child: linksListController == null
                    ? const SizedBox()
                    : ChatDetailsLinksPage(
                        key: const PageStorageKey<String>('Links'),
                        controller: linksListController!,
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

  void onTapAddMembers() {
    openDialogInvite();
  }

  void onToggleNotification() async {
    if (muteNotifier.value == PushRuleState.notify) {
      await room?.mute();
      muteNotifier.value = PushRuleState.mentionsOnly;
    } else {
      await room?.unmute();
      muteNotifier.value = PushRuleState.notify;
    }
  }

  void onTapEditButton() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          return ChatDetailsEdit(
            roomId: roomId!,
          );
        },
      ),
    );
  }

  void onTapInviteLink(BuildContext context, String inviteLink) async {
    await Clipboard.instance.copyText(inviteLink);
    TwakeSnackBar.show(
      context,
      L10n.of(context)!.copiedToClipboard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ChatDetailViewStyle.fixedWidth,
      child: ChatDetailsView(this),
    );
  }
}
