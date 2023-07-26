import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/pages/search/recent_contacts_banner_widget.dart';
import 'package:fluffychat/pages/search/recent_item_widget.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/search/search_view_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

class SearchView extends StatefulWidget {
  final SearchController searchController;
  const SearchView(this.searchController, {super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {

  List<User>? contactsList;

  @override
  void initState() {
    contactsList = widget.searchController.getContactsFromRecentChat();
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
        controller: widget.searchController.customScrollController,
        slivers: [
          if (contactsList != null && contactsList!.isNotEmpty)
            SliverAppBar(
              flexibleSpace: FlexibleSpaceBar(
                title: RecentContactsBannerWidget(
                  searchController: widget.searchController,
                  contactsList: contactsList!,
                ),
                titlePadding: const EdgeInsetsDirectional.only(start: 0.0),
              ),
            toolbarHeight: 112,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
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
    return StreamBuilder<Either<Failure, GetContactAndRecentChatSuccess>>(
        stream: widget.searchController.contactsAndRecentChatStreamController.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (snapshot.hasError || snapshot.data!.isLeft()) {
            return const SizedBox();
          }

          final contactsList = widget.searchController.getContactsAndRecentChatStream(snapshot.data!);

          if (widget.searchController.isSearchMode) {
            contactsList.sort((pre, cur) => widget.searchController.comparePresentationSearch(pre, cur));
          }

          Logs().d("SearchView:_recentChatsWidget(): --- contactsListSorted $contactsList");

          return ListView.builder(
            padding: SearchViewStyle.paddingRecentChats,
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            controller: widget.searchController.recentChatsController,
            itemCount: contactsList.length,
            itemBuilder: (BuildContext context, int i) {
              return RecentItemWidget(
                searchController: widget.searchController,
                presentationSearch: contactsList[i],
                key: Key('chat_recent_${contactsList[i].matrixId}'),
                onTap: () {
                  widget.searchController.goToChatScreen(contactsList[i]);
                },
              );
            },
          );
        }
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
                controller: widget.searchController.searchContactAndRecentChatController?.textEditingController,
                textInputAction: TextInputAction.search,
                enabled: true,
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
          ),
          const SizedBox(width: 8),
          Text(L10n.of(context)!.clear,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LinagoraRefColors.material().neutral[60])
          ),
        ],
      ),
    );
  }
}
