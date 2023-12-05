import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_shared/chat_profile_info_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ProfileInfoSharedView extends StatelessWidget {
  final ProfileInfoSharedController controller;

  const ProfileInfoSharedView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            size: 24,
          ),
        ),
        leadingWidth: 40,
        title: Text(
          L10n.of(context)!.sharedMediaAndFiles,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: NestedScrollView(
        physics: const ClampingScrollPhysics(),
        key: controller.nestedScrollViewState,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                toolbarHeight: 0,
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
                bottom: TabBar(
                  physics: const NeverScrollableScrollPhysics(),
                  overlayColor: MaterialStateProperty.all(
                    Colors.transparent,
                  ),
                  tabs: controller.profileSharedPages().map((pages) {
                    return Tab(
                      child: Text(
                        pages.page.getTitle(context),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    );
                  }).toList(),
                  controller: controller.tabController,
                ),
              ),
            ),
          ];
        },
        body: ClipRRect(
          borderRadius: BorderRadius.all(
            Radius.circular(
              ChatDetailViewStyle.chatDetailsPageViewWebBorderRadius,
            ),
          ),
          child: Container(
            width: ChatDetailViewStyle.chatDetailsPageViewWebWidth,
            padding: ChatDetailViewStyle.paddingTabBarView,
            decoration: BoxDecoration(
              color: LinagoraRefColors.material().primary[100],
            ),
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: controller.tabController,
              children: controller.profileSharedPages().map((pages) {
                return pages.child;
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
