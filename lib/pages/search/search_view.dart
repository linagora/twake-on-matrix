import 'package:fluffychat/domain/app_state/search/pre_search_state.dart';
import 'package:fluffychat/pages/search/recent_contacts_banner_widget.dart';
import 'package:fluffychat/pages/search/recent_item_widget.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/search/search_external_contact.dart';
import 'package:fluffychat/pages/search/search_text_field.dart';
import 'package:fluffychat/pages/search/search_view_style.dart';
import 'package:fluffychat/pages/search/server_search_view.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_empty_search.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_search.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:fluffychat/widgets/twake_components/twake_loading/center_loading_indicator.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class SearchView extends StatelessWidget {
  final SearchController searchController;

  const SearchView(this.searchController, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(SearchViewStyle.toolbarHeightSearch),
        child: _buildAppBarSearch(context),
      ),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        controller: searchController.scrollController,
        slivers: [
          ValueListenableBuilder(
            valueListenable: searchController.preSearchRecentContactsNotifier,
            builder: (context, value, emptyChild) =>
                value.fold((failure) => emptyChild!, (success) {
              switch (success.runtimeType) {
                case const (PreSearchRecentContactsSuccess):
                  final data = success as PreSearchRecentContactsSuccess;
                  return ValueListenableBuilder(
                    valueListenable: searchController.textEditingController,
                    builder: (context, textEditingValue, child) {
                      if (textEditingValue.text.isNotEmpty) {
                        return emptyChild!;
                      }
                      return SliverAppBar(
                        flexibleSpace: FlexibleSpaceBar(
                          title: PreSearchRecentContactsContainer(
                            searchController: searchController,
                            recentRooms: data.rooms,
                          ),
                          titlePadding:
                              const EdgeInsetsDirectional.only(start: 0.0),
                        ),
                        toolbarHeight: 112,
                        backgroundColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                      );
                    },
                  );
                default:
                  return emptyChild!;
              }
            }),
            child: const SliverToBoxAdapter(),
          ),
          _RecentChatAndContactsHeader(searchController: searchController),
          _recentChatsWidget(),
          ValueListenableBuilder(
            valueListenable:
                searchController.serverSearchController.searchResultsNotifier,
            builder: ((context, searchResults, child) {
              if (searchResults is PresentationServerSideEmptySearch) {
                return child!;
              }

              if (searchResults is PresentationServerSideSearch) {
                if (searchResults.searchResults.isEmpty) {
                  return child!;
                }
                return _SearchHeader(
                  header: L10n.of(context)!.messages,
                  searchController: searchController,
                  needShowMore: false,
                );
              }
              return child!;
            }),
            child: _EmptySliverBox(),
          ),
          ServerSearchMessagesList(searchController: searchController),
          ValueListenableBuilder(
            valueListenable:
                searchController.serverSearchController.isLoadingMoreNotifier,
            builder: (context, isLoadingMore, _) {
              return SliverToBoxAdapter(
                child: isLoadingMore
                    ? const CenterLoadingIndicator()
                    : const SizedBox(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _recentChatsWidget() {
    return SliverToBoxAdapter(
      child: ValueListenableBuilder(
        valueListenable: searchController.searchContactAndRecentChatController!
            .isShowChatsAndContactsNotifier,
        builder: (context, isShowMore, _) {
          return ValueListenableBuilder(
            valueListenable: searchController
                .searchContactAndRecentChatController!
                .recentAndContactsNotifier,
            builder: (context, contacts, emptyChild) {
              if (contacts.isEmpty) {
                final keyword = searchController.textEditingController.text;
                if (searchController.isSearchMatrixUserId) {
                  return SearchExternalContactWidget(
                    keyword: keyword,
                    searchController: searchController,
                  );
                }
                return emptyChild!;
              }

              if (searchController.isShowMore) {
                return const SizedBox.shrink();
              }

              return ListView.builder(
                padding: SearchViewStyle.paddingRecentChats,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return RecentItemWidget(
                    highlightKeyword:
                        searchController.textEditingController.text,
                    presentationSearch: contacts[index],
                    client: searchController.client,
                    key: Key('chat_recent_${contacts[index].id}'),
                    onTap: () {
                      searchController.onSearchItemTap(contacts[index]);
                    },
                  );
                },
              );
            },
            child: const SizedBox(),
          );
        },
      ),
    );
  }

  Widget _buildAppBarSearch(BuildContext context) {
    return AppBar(
      toolbarHeight: SearchViewStyle.toolbarHeightSearch,
      backgroundColor: LinagoraSysColors.material().onPrimary,
      leadingWidth: double.infinity,
      leading: Padding(
        padding: SearchViewStyle.paddingLeadingAppBar,
        child: Row(
          children: [
            TwakeIconButton(
              tooltip: L10n.of(context)!.back,
              icon: Icons.chevron_left_outlined,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: SearchTextField(
                textEditingController: searchController.textEditingController,
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size(double.infinity, 6),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.08),
          height: 1,
        ),
      ),
    );
  }
}

class _RecentChatAndContactsHeader extends StatelessWidget {
  const _RecentChatAndContactsHeader({
    required this.searchController,
  });

  final SearchController searchController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: searchController.textEditingController,
      builder: ((context, value, _) {
        final searchTerm = value.text;
        return ValueListenableBuilder(
          valueListenable: searchController
              .searchContactAndRecentChatController!.recentAndContactsNotifier,
          builder: (context, contacts, _) {
            if (searchTerm.isNotEmpty && contacts.isEmpty) {
              return _EmptySliverBox();
            }
            return _SearchHeader(
              searchController: searchController,
              header: searchTerm.isEmpty
                  ? L10n.of(context)!.recent
                  : L10n.of(context)!.chatsAndContacts,
              needShowMore: value.text.isNotEmpty,
            );
          },
        );
      }),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final String header;

  final SearchController searchController;

  final bool needShowMore;

  const _SearchHeader({
    required this.header,
    required this.searchController,
    this.needShowMore = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      toolbarHeight: SearchViewStyle.toolbarHeightOfSliverAppBar,
      flexibleSpace: FlexibleSpaceBar(
        title: _chatsHeaders(
          context,
          header,
          needShowMore: needShowMore,
        ),
        titlePadding: SearchViewStyle.appbarPadding,
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      pinned: true,
    );
  }

  Widget _chatsHeaders(
    BuildContext context,
    String headerText, {
    bool needShowMore = true,
  }) {
    return Container(
      width: double.infinity,
      height: SearchViewStyle.toolbarHeightOfSliverAppBar,
      padding: SearchViewStyle.paddingRecentChatsHeaders,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              headerText,
              style: SearchViewStyle.headerTextStyle(context),
            ),
          ),
          if (needShowMore)
            InkWell(
              onTap: () {
                searchController.searchContactAndRecentChatController!
                    .toggleShowMore();
              },
              child: ValueListenableBuilder(
                valueListenable: searchController
                    .searchContactAndRecentChatController!
                    .isShowChatsAndContactsNotifier,
                builder: (context, isShowMore, _) {
                  return Text(
                    isShowMore
                        ? L10n.of(context)!.showMore
                        : L10n.of(context)!.showLess,
                    style: SearchViewStyle.headerTextStyle(context),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptySliverBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: SizedBox.shrink(),
    );
  }
}
