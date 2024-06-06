import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_page_enum.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/links/chat_details_links_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/media/chat_details_media_page.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_view.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/chat_details/chat_details_page_model.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatProfileInfo extends StatefulWidget {
  final VoidCallback? onBack;
  final String? roomId;
  final PresentationContact? contact;
  final bool isInStack;
  final bool isDraftInfo;

  const ChatProfileInfo({
    super.key,
    required this.onBack,
    required this.isInStack,
    this.roomId,
    this.contact,
    required this.isDraftInfo,
  });

  @override
  State<ChatProfileInfo> createState() => ChatProfileInfoController();
}

class ChatProfileInfoController extends State<ChatProfileInfo>
    with
        HandleVideoDownloadMixin,
        PlayVideoActionMixin,
        SingleTickerProviderStateMixin {
  final _lookupMatchContactInteractor =
      getIt.get<LookupMatchContactInteractor>();

  StreamSubscription? lookupContactNotifierSub;

  final ValueNotifier<Either<Failure, Success>> lookupContactNotifier =
      ValueNotifier<Either<Failure, Success>>(
    const Right(LookupContactsInitial()),
  );

  final GlobalKey<NestedScrollViewState> nestedScrollViewState = GlobalKey();

  final List<ChatDetailsPage> profileSharedPagesList = [
    ChatDetailsPage.media,
    ChatDetailsPage.links,
    ChatDetailsPage.files,
  ];

  SameTypeEventsBuilderController? _mediaListController;
  SameTypeEventsBuilderController? _linksListController;
  SameTypeEventsBuilderController? _filesListController;
  TabController? tabController;

  Timeline? _timeline;

  Room? get room => widget.roomId != null
      ? Matrix.of(context).client.getRoomById(widget.roomId!)
      : null;

  User? get user =>
      room?.unsafeGetUserFromMemoryOrFallback(room?.directChatMatrixID ?? '');

  static const _mediaFetchLimit = 20;
  static const _linksFetchLimit = 20;
  static const _filesFetchLimit = 20;

  Future<Timeline> _getTimeline() async {
    _timeline ??= await room!.getTimeline();
    return _timeline!;
  }

  void lookupMatchContactAction() {
    lookupContactNotifierSub = _lookupMatchContactInteractor
        .execute(
          val: widget.contact?.matrixId ?? user?.id ?? '',
        )
        .listen(
          (event) => lookupContactNotifier.value = event,
        );
  }

  List<ChatDetailsPageModel> profileSharedPages() => profileSharedPagesList.map(
        (page) {
          switch (page) {
            case ChatDetailsPage.media:
              return ChatDetailsPageModel(
                page: page,
                child: _mediaListController == null
                    ? const SizedBox()
                    : ChatDetailsMediaPage(
                        key: const PageStorageKey(
                          'ChatProfileInfoSharedMedia',
                        ),
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
                        key: const PageStorageKey(
                          'ChatProfileInfoSharedLinks',
                        ),
                        controller: _linksListController!,
                      ),
              );
            case ChatDetailsPage.files:
              return ChatDetailsPageModel(
                page: page,
                child: _filesListController == null
                    ? const SizedBox()
                    : ChatDetailsFilesPage(
                        key: const PageStorageKey(
                          'ChatProfileInfoSharedFiles',
                        ),
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

  void _initSharedMediaControllers() {
    tabController = TabController(
      length: profileSharedPagesList.length,
      vsync: this,
    );
    _mediaListController = SameTypeEventsBuilderController(
      getTimeline: _getTimeline,
      searchFunc: (event) => event.isVideoOrImage,
      limit: _mediaFetchLimit,
    );
    _linksListController = SameTypeEventsBuilderController(
      getTimeline: _getTimeline,
      searchFunc: (event) => event.isContainsLink,
      limit: _linksFetchLimit,
    );
    _filesListController = SameTypeEventsBuilderController(
      getTimeline: _getTimeline,
      searchFunc: (event) => event.isAFile,
      limit: _filesFetchLimit,
    );
  }

  void _listenerInnerController() {
    if (nestedScrollViewState.currentState?.innerController.shouldLoadMore ==
            true &&
        tabController?.index != null) {
      switch (profileSharedPagesList[tabController!.index]) {
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

  void _refreshDataInTabviewInit() {
    _linksListController?.refresh();
    _mediaListController?.refresh();
    _filesListController?.refresh();
  }

  @override
  void initState() {
    lookupMatchContactAction();
    _initSharedMediaControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nestedScrollViewState.currentState?.innerController.addListener(
        _listenerInnerController,
      );
      _refreshDataInTabviewInit();
    });
    super.initState();
  }

  @override
  void dispose() {
    tabController?.dispose();
    _mediaListController?.dispose();
    _linksListController?.dispose();
    _filesListController?.dispose();
    nestedScrollViewState.currentState?.innerController.dispose();
    lookupContactNotifier.dispose();
    lookupContactNotifierSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatProfileInfoView(this);
  }
}
