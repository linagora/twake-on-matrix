import 'package:fluffychat/pages/search/search_view_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/pages/dialer/pip/dismiss_keyboard.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController textEditingController;

  const SearchTextField({
    super.key,
    required this.textEditingController,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16.0),
      child: TextField(
        onTapOutside: (event) {
          dismissKeyboard(context);
        },
        controller: textEditingController,
        textInputAction: TextInputAction.search,
        enabled: true,
        autofocus: true,
        decoration: InputDecoration(
          filled: true,
          contentPadding: SearchViewStyle.contentPaddingAppBar,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: SearchViewStyle.borderRadiusTextField,
          ),
          hintText: L10n.of(context)!.search,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          prefixIcon: Icon(
            Icons.search_outlined,
            size: SearchViewStyle.searchIconSize,
            color: Theme.of(context).colorScheme.onSurface,
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
