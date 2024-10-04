import 'package:fluffychat/pages/search/search_view_style.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/pages/dialer/pip/dismiss_keyboard.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool autofocus;
  final String? hintText;
  final FocusNode? focusNode;

  const SearchTextField({
    super.key,
    required this.textEditingController,
    this.autofocus = true,
    this.hintText,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.all(Radius.circular(24.0)),
      child: TextField(
        onTapOutside: (event) {
          dismissKeyboard(context);
        },
        controller: textEditingController,
        textInputAction: TextInputAction.search,
        contextMenuBuilder: mobileTwakeContextMenuBuilder,
        enabled: true,
        focusNode: focusNode,
        autofocus: autofocus,
        decoration: InputDecoration(
          filled: true,
          contentPadding: SearchViewStyle.contentPaddingAppBar,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: SearchViewStyle.borderRadiusTextField,
          ),
          hintText: hintText ?? L10n.of(context)!.search,
          hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: LinagoraRefColors.material().neutral[60],
              ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          prefixIcon: Icon(
            Icons.search_outlined,
            size: SearchViewStyle.searchIconSize,
            color: LinagoraRefColors.material().neutral[60],
          ),
          suffixIcon: ValueListenableBuilder(
            valueListenable: textEditingController,
            builder: (context, value, child) {
              return value.text.isNotEmpty ? child! : const SizedBox.shrink();
            },
            child: TwakeIconButton(
              tooltip: L10n.of(context)!.close,
              icon: Icons.close,
              onTap: () {
                textEditingController.clear();
              },
            ),
          ),
        ),
      ),
    );
  }
}
