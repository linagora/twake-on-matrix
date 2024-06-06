import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_page_enum.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/links/chat_details_links_page.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/media/chat_details_media_page.dart';
import 'package:fluffychat/presentation/model/chat_details/chat_details_page_model.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin ChatDetailsTabMixin {
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

  static const _mediaFetchLimit = 20;
  static const _linksFetchLimit = 20;
  static const _filesFetchLimit = 20;

  Future<Timeline> _getTimeline(Room room) async {
    _timeline ??= await room.getTimeline();
    return _timeline!;
  }

  List<ChatDetailsPageModel> profileSharedPages(
    Future<String> Function(Event) handleDownloadVideoEvent,
  ) =>
      profileSharedPagesList.map(
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
                        handleDownloadVideoEvent: handleDownloadVideoEvent,
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

  void initSharedMediaControllers(
    Room room,
    TickerProvider vsync,
  ) {
    tabController = TabController(
      length: profileSharedPagesList.length,
      vsync: vsync,
    );
    _mediaListController = SameTypeEventsBuilderController(
      getTimeline: () => _getTimeline(room),
      searchFunc: (event) => event.isVideoOrImage,
      limit: _mediaFetchLimit,
    );
    _linksListController = SameTypeEventsBuilderController(
      getTimeline: () => _getTimeline(room),
      searchFunc: (event) => event.isContainsLink,
      limit: _linksFetchLimit,
    );
    _filesListController = SameTypeEventsBuilderController(
      getTimeline: () => _getTimeline(room),
      searchFunc: (event) => event.isAFile,
      limit: _filesFetchLimit,
    );
  }

  void listenerInnerController(
    GlobalKey<NestedScrollViewState> nestedScrollViewState,
  ) {
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

  void refreshDataInTabViewInit() {
    _linksListController?.refresh();
    _mediaListController?.refresh();
    _filesListController?.refresh();
  }

  void disposeSharedMediaControllers() {
    _mediaListController?.dispose();
    _linksListController?.dispose();
    _filesListController?.dispose();
    tabController?.dispose();
  }
}
