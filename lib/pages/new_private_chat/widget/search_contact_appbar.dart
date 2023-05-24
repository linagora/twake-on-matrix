import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:vrouter/vrouter.dart';

class SearchContactAppBar extends StatefulWidget {

  final SearchContactsController searchContactsController;
  final void Function() onCloseSearchBar;

  final String title;

  final String? hintText;

  const SearchContactAppBar({
    super.key,
    required this.searchContactsController,
    required this.onCloseSearchBar,
    required this.title,
    this.hintText,
  });

  @override
  State<SearchContactAppBar> createState() => _SearchContactAppBarState();
}

class _SearchContactAppBarState extends State<SearchContactAppBar> {
  bool isSearchBarShow = false;

  late final SearchContactsController searchContactController = widget.searchContactsController;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.15))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 1),
                blurRadius: 80,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 1),
                blurRadius: 3,
                spreadRadius: 0.5,
              ),
            ],
          ),)),
    automaticallyImplyLeading: false,
    backgroundColor: Theme.of(context).colorScheme.background,
    titleSpacing: 0,
    leading: TwakeIconButton(
      icon: Icons.arrow_back,
      onPressed: () => VRouter.of(context).pop(),
      tooltip: "Back",
      paddingAll: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
    ),
    title: isSearchBarShow 
      ? Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextField(
          autofocus: true,
          maxLines: 1,
          buildCounter: (
            BuildContext context, {
            required int currentLength,
            required int? maxLength,
            required bool isFocused,
          }) => const SizedBox.shrink(),
          maxLength: 200,
          cursorHeight: 26,
          scrollPadding: const EdgeInsets.all(0),
          controller: searchContactController.textEditingController,
          decoration: InputDecoration(
            isCollapsed: true,
            hintText: widget.hintText,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: LinagoraRefColors.material().neutral[60],
            ),
          ),
        ),
      )
      : Text(
        widget.title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface
      ),),
    actions: isSearchBarShow
      ? [
        TwakeIconButton(
          onPressed: () {
            setState(() => isSearchBarShow = false);
            searchContactController.searchKeyword = "";
            widget.onCloseSearchBar();
          }, 
          tooltip: "Close",
          icon: Icons.close,
          paddingAll: 10.0,
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),),
      ]
      : [
        TwakeIconButton(
          icon: Icons.search,
          onPressed: () => openSearchBar(), 
          tooltip: "Search",
          paddingAll: 10.0,
          margin: const EdgeInsets.symmetric(vertical: 10.0),),
        TwakeIconButton(
          icon: Icons.more_vert,
          onPressed: () {}, 
          tooltip: "More",
          paddingAll: 10.0,
          margin: const EdgeInsets.symmetric(vertical: 10.0),),
      ],
      );
  }

  void openSearchBar() {
    setState(() {
      isSearchBarShow = true;
    });
  }
}