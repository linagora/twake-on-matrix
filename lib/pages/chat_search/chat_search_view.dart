import 'package:fluffychat/pages/chat_search/chat_recent_item_widget.dart';
import 'package:fluffychat/pages/chat_search/chat_search.dart';
import 'package:fluffychat/pages/chat_search/chat_search_view_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:vrouter/vrouter.dart';

class ChatSearchView extends StatefulWidget {
  final ChatSearchController chatSearchController;
  const ChatSearchView(this.chatSearchController, {super.key});

  @override
  State<ChatSearchView> createState() => _ChatSearchViewState();
}

class _ChatSearchViewState extends State<ChatSearchView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: _buildAppBarChatSearch(context)),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        controller: widget.chatSearchController.customScrollController,
        slivers: [
          SliverAppBar(
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 100,
                    color: Colors.red,
                  ),
                ],
              ),
              titlePadding: const EdgeInsetsDirectional.only(
                start: 0.0,
              ),
            ),
            toolbarHeight: 100,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
          ),
          SliverAppBar(
            toolbarHeight: ChatSearchViewStyle.toolbarHeightOfSliverAppBar,
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
    final rooms = widget.chatSearchController.filteredRoomsForAll;
    if (rooms.isEmpty) {
      const SizedBox();
    } else {
      return ListView.builder(
        padding: ChatSearchViewStyle.paddingRecentChats,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        controller: widget.chatSearchController.recentChatsController,
        itemCount: rooms.length,
        itemBuilder: (BuildContext context, int i) {
          return ChatRecentItemWidget(
            rooms[i],
            key: Key('chat_recent_${rooms[i].id}'),
            onTap: () {},
          );
        },
      );
    }
    return const SizedBox();
  }


  Widget _buildAppBarChatSearch(BuildContext context) {
    return AppBar(
      toolbarHeight: ChatSearchViewStyle.toolbarHeightChatSearch,
      surfaceTintColor: Colors.transparent,
      leadingWidth: double.infinity,
      leading: Padding(
        padding: ChatSearchViewStyle.paddingLeadingAppBar,
        child: Row(
          children: [
            TwakeIconButton(
              tooltip: L10n.of(context)!.back,
              icon: Icons.arrow_back,
              onPressed: () {
                VRouter.of(context).pop();
              },
              paddingAll: 8.0,
              margin: ChatSearchViewStyle.marginIconBack,
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: TextField(
                // controller: controller.searchChatController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {},
                enabled: false,
                decoration: InputDecoration(
                  filled: true,
                  contentPadding: ChatSearchViewStyle.contentPaddingAppBar,
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
      height: ChatSearchViewStyle.toolbarHeightOfSliverAppBar,
      padding: ChatSearchViewStyle.paddingRecentChatsHeaders,
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
