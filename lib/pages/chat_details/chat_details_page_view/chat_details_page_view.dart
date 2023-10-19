import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_page_view_style.dart';
import 'package:fluffychat/presentation/model/chat_details/chat_details_page_model.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

typedef OnTapGoToPage = void Function(int);

class ChatDetailsPageViewBuilder extends StatelessWidget {
  final List<ChatDetailsPageModel> pages;
  final int currentIndexPageSelected;
  final PageController pageController;
  final OnTapGoToPage onTapGoToPage;

  const ChatDetailsPageViewBuilder({
    super.key,
    required this.pages,
    required this.currentIndexPageSelected,
    required this.onTapGoToPage,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tabBarPageViewBuilder(),
        Expanded(
          child: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: pages.map((page) => page.child).toList(),
          ),
        ),
      ],
    );
  }

  Widget _tabBarPageViewBuilder() {
    return SizedBox(
      height: ChatDetailsPageViewStyle.tabBarPageViewHeight,
      child: ListView.separated(
        padding: ChatDetailsPageViewStyle.tabBarPageViewPadding,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => onTapGoToPage(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _titleTabBarPageViewBuilder(
                    context: context,
                    title: pages[index].page.getTitle(context),
                    index: index,
                  ),
                  const SizedBox(height: 11),
                  _highlightTitlePageSelected(context, index),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: pages.length,
      ),
    );
  }

  Widget _highlightTitlePageSelected(
    BuildContext context,
    int index,
  ) {
    return Container(
      width: _getSizeTitleTabBarPage(
            context,
            pages[index].page.getTitle(context),
          ).size.width +
          ChatDetailsPageViewStyle.tabBarPageViewIndicatorBonus,
      height: ChatDetailsPageViewStyle.tabBarPageViewIndicatorHeight,
      decoration: ShapeDecoration(
        color: currentIndexPageSelected != index
            ? Colors.transparent
            : LinagoraSysColors.material().primary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              ChatDetailsPageViewStyle.tabBarPageViewIndicatorBorder,
            ),
            topRight: Radius.circular(
              ChatDetailsPageViewStyle.tabBarPageViewIndicatorBorder,
            ),
          ),
        ),
      ),
    );
  }

  Text _titleTabBarPageViewBuilder({
    required BuildContext context,
    required String title,
    required int index,
  }) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: currentIndexPageSelected == index
                ? LinagoraSysColors.material().primary
                : LinagoraSysColors.material().onSurface,
          ),
    );
  }

  TextPainter _getSizeTitleTabBarPage(
    BuildContext context,
    String title,
  ) {
    return TextPainter(
      text: TextSpan(
        text: title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: LinagoraSysColors.material().primary,
            ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
  }
}
