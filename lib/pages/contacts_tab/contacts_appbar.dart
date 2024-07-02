import 'package:fluffychat/pages/contacts_tab/contacts_appbar_style.dart';
import 'package:fluffychat/pages/search/search_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ContactsAppBar extends StatelessWidget {
  final ValueNotifier<bool> isSearchModeNotifier;
  final FocusNode searchFocusNode;
  final TextEditingController textEditingController;
  final Function()? clearSearchBar;

  const ContactsAppBar({
    super.key,
    required this.isSearchModeNotifier,
    required this.searchFocusNode,
    required this.textEditingController,
    this.clearSearchBar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ContactsAppbarStyle.appbarPadding,
      child: Column(
        children: [
          AppBar(
            backgroundColor: LinagoraSysColors.material().onPrimary,
            toolbarHeight: ContactsAppbarStyle.toolbarHeight,
            automaticallyImplyLeading: false,
            leadingWidth: ContactsAppbarStyle.leadingWidth,
            centerTitle: true,
            title: Align(
              alignment: ContactsAppbarStyle.alignment,
              child: Text(
                L10n.of(context)!.contacts,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isSearchModeNotifier,
            builder: (context, isSearchMode, child) {
              return SizedBox(
                height: ContactsAppbarStyle.textFieldHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: SearchTextField(
                        textEditingController: textEditingController,
                        hintText: L10n.of(context)!.searchForContacts,
                        autofocus: false,
                        focusNode: searchFocusNode,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
