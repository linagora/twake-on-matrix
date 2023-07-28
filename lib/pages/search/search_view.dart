import 'package:fluffychat/domain/app_state/search/pre_search_state.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/model/extensions/search/search_list_extension.dart';
import 'package:fluffychat/pages/search/recent_contacts_banner_widget.dart';
import 'package:fluffychat/pages/search/recent_item_widget.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/search/search_view_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:vrouter/vrouter.dart';

class SearchView extends StatefulWidget {
  final SearchController searchController;
  const SearchView(this.searchController, {super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: _buildAppBarSearch(context)),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        controller: widget.searchController.recentChatsController,
        slivers: [
          ValueListenableBuilder(
            valueListenable: widget.searchController.preSearchRecentContactsNotifier,
            builder: (context, value, child) => value.fold(
              (failure) => const SliverToBoxAdapter(child: SizedBox()), 
              (success) {
                switch(success.runtimeType) {
                  case PreSearchRecentContactsSuccess: 
                    final data = success as PreSearchRecentContactsSuccess;
                    return SliverAppBar(
                      flexibleSpace: FlexibleSpaceBar(
                        title: PreSearchRecentContactsContainer(
                          searchController: widget.searchController,
                          contactsList: data.users,
                        ),
                        titlePadding: const EdgeInsetsDirectional.only(start: 0.0),
                      ),
                      toolbarHeight: 112,
                      backgroundColor: Colors.transparent,
                      automaticallyImplyLeading: false
                    );
                  default: return const SliverToBoxAdapter(child: SizedBox());
                }
              }
            )
          ),
          SliverAppBar(
            toolbarHeight: SearchViewStyle.toolbarHeightOfSliverAppBar,
            flexibleSpace:  FlexibleSpaceBar(
              title: _recentChatsHeaders(context),
              titlePadding: const EdgeInsetsDirectional.only(
                bottom: 0.0,
                top: 0.0,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            pinned: true,
          ),
          SliverAnimatedList(
            itemBuilder: (_, index, ___){
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _recentChatsWidget(),
                ],
              );
            },
            initialItemCount: 1,
          )
        ],
      ),
    );
  }

  Widget _recentChatsWidget() {
    return ValueListenableBuilder(
      valueListenable: widget.searchController.searchContactAndRecentChatController!.recentAndContactsNotifier,
      builder: (context, value, child) => value.fold(
        (failure) => const SizedBox(), 
        (success) {
          switch(success.runtimeType) {
            case GetContactAndRecentChatSuccess:
            final data = success as GetContactAndRecentChatSuccess;
            final contactsList = data.searchResult.toPresentationSearch();
              return ListView.builder(
                padding: SearchViewStyle.paddingRecentChats,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                controller: widget.searchController.searchContactAndRecentChatScrollController,
                itemCount: contactsList.length + (true ? 1 : 0),   // FIXME: fix LOAD MORE nhe Minh
                itemBuilder: (context, index) {
                  // if (i >= contactsList.length) {
                  //   return const Center(child: CircularProgressIndicator());
                  // }
                  return RecentItemWidget(
                    highlightKeyword: data.keyword,
                    presentationSearch: contactsList[index],
                    key: Key('chat_recent_${contactsList[index].matrixId}'),
                    onTap: () {
                      widget.searchController.goToChatScreen(contactsList[index]);
                    },
                  );
                },
              );
            default: return const SizedBox();
          }
        }
      )
    );
  }


  Widget _buildAppBarSearch(BuildContext context) {
    return AppBar(
      toolbarHeight: SearchViewStyle.toolbarHeightSearch,
      surfaceTintColor: Colors.transparent,
      leadingWidth: double.infinity,
      leading: Padding(
        padding: SearchViewStyle.paddingLeadingAppBar,
        child: Row(
          children: [
            TwakeIconButton(
              tooltip: L10n.of(context)!.back,
              icon: Icons.arrow_back,
              onPressed: () {
                VRouter.of(context).pop();
              },
              paddingAll: 8.0,
              margin: SearchViewStyle.marginIconBack,
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: TextField(
                controller: widget.searchController.textEditingController,
                textInputAction: TextInputAction.search,
                enabled: true,
                autofocus: true,
                decoration: InputDecoration(
                  filled: true,
                  contentPadding: SearchViewStyle.contentPaddingAppBar,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  hintText: L10n.of(context)!.search,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  suffixIcon: Icon(
                    Icons.keyboard_voice,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size(double.infinity, 4),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.08),
          height: 1)),
    );
  }

  Widget _recentChatsHeaders(BuildContext context) {
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
            child: Text(L10n.of(context)!.recent,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: LinagoraRefColors.material().neutral[40])
            ),
          )
        ],
      ),
    );
  }
}
