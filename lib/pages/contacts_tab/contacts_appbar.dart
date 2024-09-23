import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_appbar_style.dart';
import 'package:fluffychat/pages/search/search_text_field.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ContactsAppBar extends StatelessWidget {
  final ValueNotifier<bool> isSearchModeNotifier;
  final FocusNode searchFocusNode;
  final TextEditingController textEditingController;
  final Function()? clearSearchBar;
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  const ContactsAppBar({
    super.key,
    required this.isSearchModeNotifier,
    required this.searchFocusNode,
    required this.textEditingController,
    this.clearSearchBar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: responsiveUtils.isMobile(context)
              ? LinagoraSysColors.material().background
              : LinagoraSysColors.material().onPrimary,
          toolbarHeight: ContactsAppbarStyle.toolbarHeight,
          automaticallyImplyLeading: false,
          leadingWidth: ContactsAppbarStyle.leadingWidth,
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: ContactsAppbarStyle.alignmentTitle(context),
                  child: Text(
                    L10n.of(context)!.contacts,
                    style: responsiveUtils.isMobile(context)
                        ? LinagoraTextStyle.material().bodyLarge1.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: ContactsAppbarStyle.textStyleHeight,
                            )
                        : Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                  ),
                ),
              ),
              IconButton(
                onPressed: null,
                icon: Icon(
                  Icons.person_add_alt_1_outlined,
                  color: LinagoraSysColors.material().primary,
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isSearchModeNotifier,
          builder: (context, isSearchMode, child) {
            return Container(
              decoration: BoxDecoration(
                color: LinagoraSysColors.material().background,
                border: Border(
                  bottom: BorderSide(
                    color: LinagoraSysColors.material().surface,
                    width: 1.0,
                  ),
                ),
              ),
              height: ContactsAppbarStyle.textFieldHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
              ),
            );
          },
        ),
      ],
    );
  }
}
