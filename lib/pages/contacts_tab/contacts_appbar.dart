import 'package:fluffychat/pages/contacts_tab/contacts_appbar_style.dart';
import 'package:fluffychat/pages/dialer/pip/dismiss_keyboard.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
    return AppBar(
      toolbarHeight: ContactsAppbarStyle.preferredSizeAppBar.height,
      surfaceTintColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Colors.black,
      shadowColor: Colors.black.withOpacity(0.15),
      elevation: 4.0,
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Colors.black,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Padding(
        padding: ContactsAppbarStyle.paddingTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.of(context)!.contacts,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black.withOpacity(0.15)),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ValueListenableBuilder<bool>(
                valueListenable: isSearchModeNotifier,
                builder: (context, isSearchMode, child) {
                  return SizedBox(
                    height: 48,
                    child: TextField(
                      onTapOutside: (event) {
                        dismissKeyboard();
                      },
                      focusNode: searchFocusNode,
                      controller: textEditingController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(0),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        hintText: L10n.of(context)!.searchForContacts,
                        prefixIcon: const Icon(
                          Icons.search_outlined,
                        ),
                        suffixIcon: isSearchMode
                            ? TwakeIconButton(
                                tooltip: "Clear",
                                icon: Icons.close,
                                onPressed: clearSearchBar,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
