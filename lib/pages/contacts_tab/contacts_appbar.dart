import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_appbar_style.dart';
import 'package:fluffychat/pages/search/search_text_field.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
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
        TwakeAppBar(
          title: L10n.of(context)!.contacts,
          context: context,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isSearchModeNotifier,
          builder: (context, isSearchMode, child) {
            return Container(
              decoration: BoxDecoration(
                color: responsiveUtils.isMobile(context)
                    ? LinagoraSysColors.material().background
                    : LinagoraSysColors.material().onPrimary,
              ),
              height: ContactsAppbarStyle.textFieldHeight,
              child: Padding(
                padding: ContactsAppbarStyle.searchFieldPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SearchTextField(
                        textEditingController: textEditingController,
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
        if (responsiveUtils.isMobile(context))
          Divider(
            height: ContactsAppbarStyle.dividerHeight,
            thickness: ContactsAppbarStyle.dividerThickness,
            color: LinagoraStateLayer(LinagoraSysColors.material().surfaceTint)
                .opacityLayer3,
          ),
      ],
    );
  }
}
