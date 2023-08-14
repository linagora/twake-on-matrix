import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import '../../utils/responsive/responsive_utils.dart';

class ContactsAppBar extends StatelessWidget {
  final ContactsTabController controller;

  const ContactsAppBar(
    this.controller, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 16.0,
          top: ResponsiveUtils().isMobile(context) ? 30 : 8,
        ),
        child: Text(
          L10n.of(context)!.contacts,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black.withOpacity(0.15)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ValueListenableBuilder<bool>(
            valueListenable: controller.isSearchModeNotifier,
            builder: (context, isSearchMode, child) {
              return SizedBox(
                height: 48,
                child: TextField(
                  focusNode: controller.searchFocusNode,
                  controller: controller.textEditingController,
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
                            onPressed: () => controller.clearSearchBar(),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
