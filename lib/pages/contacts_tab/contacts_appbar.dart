import 'package:fluffychat/pages/contacts_tab/contacts_appbar_style.dart';
import 'package:fluffychat/pages/dialer/pip/dismiss_keyboard.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
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
                      child: TextField(
                        onTapOutside: (event) {
                          dismissKeyboard(context);
                        },
                        focusNode: searchFocusNode,
                        controller: textEditingController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          contentPadding: ContactsAppbarStyle.contentPadding,
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ContactsAppbarStyle.textFieldBorderRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          hintText: L10n.of(context)!.searchForContacts,
                          hintStyle: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: LinagoraRefColors.material().neutral[60],
                              ),
                          prefixIcon: Icon(
                            Icons.search_outlined,
                            size: ContactsAppbarStyle.iconSize,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          suffixIcon: isSearchMode
                              ? TwakeIconButton(
                                  tooltip: L10n.of(context)!.clear,
                                  icon: Icons.close,
                                  onTap: clearSearchBar,
                                  size: ContactsAppbarStyle.iconSize,
                                  iconColor:
                                      Theme.of(context).colorScheme.onSurface,
                                )
                              : null,
                        ),
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
