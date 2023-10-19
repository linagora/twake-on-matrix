import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/chat_details_actions_enum.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_members_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_page_enum.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/links/chat_details_links_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/media/chat_details_media_page.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection_web.dart';
import 'package:fluffychat/presentation/enum/settings/settings_profile_enum.dart';
import 'package:fluffychat/presentation/extensions/room_summary_extension.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/chat_details/chat_details_page_model.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat_details/chat_details_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';

enum AliasActions { copy, delete, setCanonical }

class ChatDetails extends StatefulWidget {
  final String roomId;

  const ChatDetails({super.key, required this.roomId});

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

  SameTypeEventsBuilderController? mediaListController;
  SameTypeEventsBuilderController? linksListController;

  Room? room;

  final responsive = getIt.get<ResponsiveUtils>();

  TabController? tabController;

  final muteNotifier = ValueNotifier<PushRuleState>(
    PushRuleState.notify,
  );

  List<User>? members;

  bool displaySettings = false;

  String? get roomId => widget.roomId;

  bool get isMobileAndTablet =>
      responsive.isMobile(context) || responsive.isTablet(context);

  Timeline? _timeline;

  Future<Timeline> getTimeline() async {
    _timeline ??= await room!.getTimeline();
    return _timeline!;
  }

  final Map<EventId, ImageData> _mediaCacheMap = {};

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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      nestedScrollViewState.currentState!.innerController.addListener(
        _listenerInnerController,
      );
      _refreshDataInTabviewInit();
    });
    room = Matrix.of(context).client.getRoomById(roomId!);
    muteNotifier.value = room?.pushRuleState ?? PushRuleState.notify;
  }

  @override
  void dispose() {
    tabController?.dispose();
    muteNotifier.dispose();
    super.dispose();
  }

  void _listenerInnerController() {
    Logs().d("ChatDetails::currentTab - ${tabController!.index}");
    if (nestedScrollViewState.currentState!.innerController.shouldLoadMore) {
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

  void toggleDisplaySettings() =>
      setState(() => displaySettings = !displaySettings);

  void setDisplaynameAction() async {
    final room = Matrix.of(context).client.getRoomById(roomId!)!;
    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.changeTheNameOfTheGroup,
      okLabel: L10n.of(context)!.ok,
      cancelLabel: L10n.of(context)!.cancel,
      textFields: [
        DialogTextField(
          initialText: room.getLocalizedDisplayname(
            MatrixLocals(
              L10n.of(context)!,
            ),
          ),
        ),
      ],
    );
    if (input == null) return;
    final success = await showFutureLoadingDialog(
      context: context,
      future: () => room.setName(input.single),
    );
    if (success.error == null) {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.displaynameHasBeenChanged,
      );
    }
  }

  void editAliases() async {
    final room = Matrix.of(context).client.getRoomById(roomId!);

    // The current endpoint doesnt seem to be implemented in Synapse. This may
    // change in the future and then we just need to switch to this api call:
    //
    // final aliases = await showFutureLoadingDialog(
    //   context: context,
    //   future: () => room.client.requestRoomAliases(room.id),
    // );
    //
    // While this is not working we use the unstable api:
    final aliases = await showFutureLoadingDialog(
      context: context,
      future: () => room!.client
          .request(
            RequestType.GET,
            '/client/unstable/org.matrix.msc2432/rooms/${Uri.encodeComponent(room.id)}/aliases',
          )
          .then((response) => List<String>.from(response['aliases'] as List)),
    );
    // Switch to the stable api once it is implemented.

    if (aliases.error != null) return;
    final adminMode = room!.canSendEvent('m.room.canonical_alias');
    if (aliases.result!.isEmpty && (room.canonicalAlias.isNotEmpty)) {
      aliases.result!.add(room.canonicalAlias);
    }
    if (aliases.result!.isEmpty && adminMode) {
      return setAliasAction();
    }
    final select = await showConfirmationDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.editRoomAliases,
      actions: [
        if (adminMode)
          AlertDialogAction(label: L10n.of(context)!.create, key: 'new'),
        ...aliases.result!
            .map((alias) => AlertDialogAction(key: alias, label: alias))
            .toList(),
      ],
    );
    if (select == null) return;
    if (select == 'new') {
      return setAliasAction();
    }
    final option = await showConfirmationDialog<AliasActions>(
      context: context,
      title: select,
      actions: [
        AlertDialogAction(
          label: L10n.of(context)!.copyToClipboard,
          key: AliasActions.copy,
          isDefaultAction: true,
        ),
        if (adminMode) ...{
          AlertDialogAction(
            label: L10n.of(context)!.setAsCanonicalAlias,
            key: AliasActions.setCanonical,
            isDestructiveAction: true,
          ),
          AlertDialogAction(
            label: L10n.of(context)!.delete,
            key: AliasActions.delete,
            isDestructiveAction: true,
          ),
        },
      ],
    );
    if (option == null) return;
    switch (option) {
      case AliasActions.copy:
        await Clipboard.setData(ClipboardData(text: select));
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.copiedToClipboard,
        );
        break;
      case AliasActions.delete:
        await showFutureLoadingDialog(
          context: context,
          future: () => room.client.deleteRoomAlias(select),
        );
        break;
      case AliasActions.setCanonical:
        await showFutureLoadingDialog(
          context: context,
          future: () => room.client.setRoomStateWithKey(
            room.id,
            EventTypes.RoomCanonicalAlias,
            '',
            {
              'alias': select,
            },
          ),
        );
        break;
    }
  }

  void setAliasAction() async {
    final room = Matrix.of(context).client.getRoomById(roomId!)!;
    final domain = room.client.userID!.domain;

    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.setInvitationLink,
      okLabel: L10n.of(context)!.ok,
      cancelLabel: L10n.of(context)!.cancel,
      textFields: [
        DialogTextField(
          prefixText: '#',
          suffixText: domain,
          hintText: L10n.of(context)!.alias,
          initialText: room.canonicalAlias.localpart,
        ),
      ],
    );
    if (input == null) return;
    await showFutureLoadingDialog(
      context: context,
      future: () =>
          room.client.setRoomAlias('#${input.single}:${domain!}', room.id),
    );
  }

  void setTopicAction() async {
    final room = Matrix.of(context).client.getRoomById(roomId!)!;
    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.setGroupDescription,
      okLabel: L10n.of(context)!.ok,
      cancelLabel: L10n.of(context)!.cancel,
      textFields: [
        DialogTextField(
          hintText: L10n.of(context)!.setGroupDescription,
          initialText: room.topic,
          minLines: 1,
          maxLines: 4,
        ),
      ],
    );
    if (input == null) return;
    final success = await showFutureLoadingDialog(
      context: context,
      future: () => room.setDescription(input.single),
    );
    if (success.error == null) {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.groupDescriptionHasBeenChanged,
      );
    }
  }

  void setGuestAccessAction(GuestAccess guestAccess) => showFutureLoadingDialog(
        context: context,
        future: () => Matrix.of(context)
            .client
            .getRoomById(roomId!)!
            .setGuestAccess(guestAccess),
      );

  void setHistoryVisibilityAction(HistoryVisibility historyVisibility) =>
      showFutureLoadingDialog(
        context: context,
        future: () => Matrix.of(context)
            .client
            .getRoomById(roomId!)!
            .setHistoryVisibility(historyVisibility),
      );

  void setJoinRulesAction(JoinRules joinRule) => showFutureLoadingDialog(
        context: context,
        future: () => Matrix.of(context)
            .client
            .getRoomById(roomId!)!
            .setJoinRules(joinRule),
      );

  void goToEmoteSettings() async {
    final room = Matrix.of(context).client.getRoomById(roomId!)!;
    // okay, we need to test if there are any emote state events other than the default one
    // if so, we need to be directed to a selection screen for which pack we want to look at
    // otherwise, we just open the normal one.
    if ((room.states['im.ponies.room_emotes'] ?? <String, Event>{})
        .keys
        .any((String s) => s.isNotEmpty)) {
      context.goChild('multiple_emotes');
    } else {
      context.goChild('emotes');
    }
  }

  void setAvatarAction() async {
    final room = Matrix.of(context).client.getRoomById(roomId!);
    final actions = [
      if (PlatformInfos.isMobile)
        SheetAction(
          key: AvatarAction.camera,
          label: L10n.of(context)!.openCamera,
          isDefaultAction: true,
          icon: Icons.camera_alt_outlined,
        ),
      SheetAction(
        key: AvatarAction.file,
        label: L10n.of(context)!.openGallery,
        icon: Icons.photo_outlined,
      ),
      if (room?.avatar != null)
        SheetAction(
          key: AvatarAction.remove,
          label: L10n.of(context)!.delete,
          isDestructiveAction: true,
          icon: Icons.delete_outlined,
        ),
    ];
    final action = actions.length == 1
        ? actions.single.key
        : await showModalActionSheet<AvatarAction>(
            context: context,
            title: L10n.of(context)!.editRoomAvatar,
            actions: actions,
          );
    if (action == null) return;
    if (action == AvatarAction.remove) {
      await showFutureLoadingDialog(
        context: context,
        future: () => room!.setAvatar(null),
      );
      return;
    }
    MatrixFile file;
    if (PlatformInfos.isMobile) {
      final result = await ImagePicker().pickImage(
        source: action == AvatarAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 50,
      );
      if (result == null) return;
      file = MatrixFile(
        bytes: await result.readAsBytes(),
        name: result.path,
      );
    } else {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final pickedFile = picked?.files.firstOrNull;
      if (pickedFile == null) return;
      file = MatrixFile(
        bytes: pickedFile.bytes!,
        name: pickedFile.name,
      );
    }
    await showFutureLoadingDialog(
      context: context,
      future: () => room!.setAvatar(file),
    );
  }

  void requestMoreMembersAction() async {
    final room = Matrix.of(context).client.getRoomById(roomId!);
    final participants = await showFutureLoadingDialog(
      context: context,
      future: () => room!.requestParticipants(),
    );
    if (participants.error == null) {
      setState(() => members = participants.result);
    }
  }

  static const fixedWidth = 360.0;

  void onPressedClose() {
    GoRouterState.of(context).path?.startsWith('/spaces/') == true
        ? context.pop()
        : context.go('/rooms/${roomId!}');
  }

  void openDialogInvite() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      useRootNavigator: PlatformInfos.isMobile ? false : true,
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

  List<ChatDetailsActions> chatDetailsActionsButton() => [
        if (responsive.isDesktop(context)) ChatDetailsActions.addMembers,
        muteNotifier.value != PushRuleState.notify
            ? ChatDetailsActions.unmute
            : ChatDetailsActions.mute,
        ChatDetailsActions.search,
        // ChatDetailsActions.more,
      ];

  List<ChatDetailsPageModel> chatDetailsPages() => chatDetailsPageView.map(
        (page) {
          switch (page) {
            case ChatDetailsPage.members:
              return ChatDetailsPageModel(
                page: page,
                child: ChatDetailsMembersPage(
                  key: const PageStorageKey("members"),
                  members: members ?? [],
                  actualMembersCount: actualMembersCount,
                  canRequestMoreMembers: members!.length < actualMembersCount,
                  requestMoreMembersAction: requestMoreMembersAction,
                  openDialogInvite: openDialogInvite,
                  isMobileAndTablet: isMobileAndTablet,
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
        eventId: event.eventId,
      ),
    );
  }

  void onTapActionsButton(ChatDetailsActions action) async {
    switch (action) {
      case ChatDetailsActions.addMembers:
        openDialogInvite();
        break;
      case ChatDetailsActions.mute:
        await room?.mute();
        muteNotifier.value = PushRuleState.mentionsOnly;
        break;
      case ChatDetailsActions.search:
        context.pop(ChatDetailsActions.search);
        break;
      case ChatDetailsActions.more:
        break;
      case ChatDetailsActions.unmute:
        await room?.unmute();
        muteNotifier.value = PushRuleState.notify;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    members ??=
        Matrix.of(context).client.getRoomById(roomId!)!.getParticipants();
    return SizedBox(
      width: fixedWidth,
      child: ChatDetailsView(this),
    );
  }
}
