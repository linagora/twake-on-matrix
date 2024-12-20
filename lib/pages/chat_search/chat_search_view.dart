import 'package:collection/collection.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/pages/chat/events/message_download_content.dart';
import 'package:fluffychat/pages/chat/events/message_download_content_web.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/pages/chat_search/chat_search.dart';
import 'package:fluffychat/pages/chat_search/chat_search_style.dart';
import 'package:fluffychat/pages/search/server_search_controller.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_empty_search.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_search.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_builder.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/result_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:fluffychat/widgets/twake_components/twake_loading/center_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ChatSearchView extends StatelessWidget {
  final ChatSearchController controller;

  const ChatSearchView(
    this.controller, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: AppBar(
        toolbarHeight: AppConfig.toolbarHeight(context),
        backgroundColor: LinagoraSysColors.material().onPrimary,
        automaticallyImplyLeading: false,
        title: _ChatSearchAppBar(controller),
      ),
      body: controller.sameTypeEventsBuilderController != null
          ? _TimelineSearchView(
              controller: controller,
              sameTypeEventsBuilderController:
                  controller.sameTypeEventsBuilderController!,
            )
          : _ServerSearchView(
              controller: controller,
              serverSearchController: controller.serverSearchController,
            ),
    );
  }
}

class _ServerSearchView extends StatelessWidget {
  const _ServerSearchView({
    required this.controller,
    required this.serverSearchController,
  });

  final ServerSearchController serverSearchController;
  final ChatSearchController controller;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller.scrollController,
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 8,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: serverSearchController.searchResultsNotifier,
          builder: (context, searchResults, child) {
            if (searchResults is PresentationServerSideSearch) {
              final events = searchResults.searchResults
                  .map((result) => result.getEvent(context))
                  .whereNotNull()
                  .toList();
              return SliverList.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _SearchItem(
                    event: event,
                    searchWord:
                        controller.serverSearchController.debouncerValue,
                    onTap: controller.onEventTap,
                  );
                },
              );
            }

            if (searchResults is PresentationServerSideEmptySearch) {
              return const SliverToBoxAdapter(
                child: EmptySearchWidget(),
              );
            }
            return child!;
          },
          child: const SliverToBoxAdapter(
            child: SizedBox(),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: serverSearchController.isLoadingMoreNotifier,
          builder: (context, isLoadingMore, child) {
            return SliverToBoxAdapter(
              child: isLoadingMore ? const CenterLoadingIndicator() : null,
            );
          },
        ),
      ],
    );
  }
}

class _TimelineSearchView extends StatelessWidget {
  const _TimelineSearchView({
    required this.controller,
    required this.sameTypeEventsBuilderController,
  });

  final ChatSearchController controller;
  final SameTypeEventsBuilderController sameTypeEventsBuilderController;

  @override
  Widget build(BuildContext context) {
    return SameTypeEventsBuilder(
      controller: sameTypeEventsBuilderController,
      scrollController: controller.scrollController,
      builder: (context, eventsState, child) {
        final success =
            eventsState.getSuccessOrNull<TimelineSearchEventSuccess>();
        final events = success?.events ?? [];
        if (events.isEmpty) {
          return _EmptyView(controller: controller);
        }
        return SliverList.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _SearchItem(
              event: event,
              searchWord: controller.serverSearchController.debouncerValue,
              onTap: controller.onEventTap,
            );
          },
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.controller,
  });

  final ChatSearchController controller;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ValueListenableBuilder(
        valueListenable:
            controller.sameTypeEventsBuilderController!.emptyNotifier,
        builder: (context, isEmpty, child) =>
            isEmpty ? const EmptySearchWidget() : const SizedBox(),
      ),
    );
  }
}

class _SearchItem extends StatelessWidget {
  final Event event;
  final String searchWord;
  final void Function(Event) onTap;

  const _SearchItem({
    required this.event,
    required this.searchWord,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: event.fetchSenderUser(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? event.senderFromMemoryOrFallback;
        return TwakeListItem(
          height: ChatSearchStyle.itemHeight,
          margin: ChatSearchStyle.itemMargin,
          child: TwakeInkWell(
            onTap: () => onTap(event),
            child: Row(
              children: [
                Padding(
                  padding: ChatSearchStyle.avatarPadding,
                  child: Avatar(
                    mxContent: user.avatarUrl,
                    name: user.calcDisplayname(),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: ChatSearchStyle.itemPadding,
                    height: ChatSearchStyle.itemHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.id == Matrix.of(context).client.userID
                                    ? L10n.of(context)!.you
                                    : user.calcDisplayname(),
                                maxLines: 1,
                                style: ListItemStyle.titleTextStyle(
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            Text(
                              event.originServerTs.localizedTimeShort(context),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: LinagoraRefColors.material()
                                        .tertiary[30],
                                  ),
                            ),
                          ],
                        ),
                        _MessageContent(event: event, searchWord: searchWord),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageContent extends StatelessWidget {
  static const _prefixLengthHighlight = 20;

  const _MessageContent({
    required this.event,
    required this.searchWord,
  });

  final Event event;
  final String searchWord;

  @override
  Widget build(BuildContext context) {
    switch (event.messageType) {
      case MessageTypes.File:
        if (PlatformInfos.isWeb) {
          return MessageDownloadContentWeb(event, highlightText: searchWord);
        } else {
          return MessageDownloadContent(event, highlightText: searchWord);
        }
      default:
        return HighlightText(
          text: event
              .calcLocalizedBodyFallback(
                MatrixLocals(L10n.of(context)!),
                hideReply: true,
                hideEdit: true,
                plaintextBody: true,
                removeMarkdown: true,
              )
              .substringToHighlight(
                searchWord,
                prefixLength: _prefixLengthHighlight,
              ),
          searchWord: searchWord,
          maxLines: 2,
          style: LinagoraTextStyle.material()
              .bodyMedium3
              .copyWith(color: LinagoraSysColors.material().onSurface),
        );
    }
  }
}

class _ChatSearchAppBar extends StatelessWidget {
  const _ChatSearchAppBar(
    this.controller,
  );

  final ChatSearchController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: ChatViewStyle.paddingLeading(context),
          child: TwakeIconButton(
            icon: Icons.chevron_left_outlined,
            onTap: controller.onBack,
            tooltip: L10n.of(context)!.back,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ChatListHeaderStyle.searchRadiusBorder,
            ),
            child: Padding(
              padding: ChatSearchStyle.inputPadding,
              child: TextField(
                controller: controller.textEditingController,
                contextMenuBuilder: mobileTwakeContextMenuBuilder,
                focusNode: controller.inputFocus,
                textInputAction: TextInputAction.search,
                autofocus: true,
                decoration:
                    ChatListHeaderStyle.searchInputDecoration(context).copyWith(
                  suffixIcon: ValueListenableBuilder(
                    valueListenable: controller.textEditingController,
                    builder: (context, value, child) => value.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              controller.textEditingController.clear();
                            },
                            icon: const Icon(Icons.close),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
