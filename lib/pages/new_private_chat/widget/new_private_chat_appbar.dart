import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:vrouter/vrouter.dart';

class NewPrivateChatAppBar extends StatefulWidget {

  final NewPrivateChatController newPrivateChatController;

  const NewPrivateChatAppBar({
    super.key,
    required this.newPrivateChatController,
  });

  @override
  State<NewPrivateChatAppBar> createState() => _NewPrivateChatAppBarState();
}

class _NewPrivateChatAppBarState extends State<NewPrivateChatAppBar> {
  bool isSearchBarShow = false;

  late final TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    textEditingController.addListener(() {
      widget.newPrivateChatController.onSearchBarChanged(textEditingController.text);
    });
  }

  @override
  void dispose() {
    super.dispose();
    textEditingController.dispose();
  }

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
      ? SizedBox(
        height: 24,
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
          controller: textEditingController,
          decoration: null,
        ),
      )
      : Text(
        L10n.of(context)!.newChat,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface
      ),),
    actions: isSearchBarShow
      ? [
        TwakeIconButton(
          onPressed: () {
            setState(() => isSearchBarShow = false);
            widget.newPrivateChatController.searchKeyword = "";
            widget.newPrivateChatController.fetchCurrentTomContacts();
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