import 'package:fluffychat/pages/dialer/pip/dismiss_keyboard.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SearchableAppBar extends StatelessWidget {
  final ValueNotifier<bool> searchModeNotifier;
  final FocusNode focusNode;
  final String title;
  final String? hintText;
  final TextEditingController textEditingController;
  final Function() toggleSearchMode;

  const SearchableAppBar({
    super.key,
    required this.searchModeNotifier,
    required this.title,
    this.hintText,
    required this.focusNode,
    required this.textEditingController,
    required this.toggleSearchMode,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: SearchableAppBarStyle.appBarHeight(context),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black.withOpacity(0.15)),
            ),
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
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      title: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            TwakeIconButton(
              icon: Icons.arrow_back,
              onPressed: () => context.pop(),
              tooltip: L10n.of(context)!.back,
              paddingAll: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: searchModeNotifier,
                builder: (context, searchModeNotifier, child) {
                  if (searchModeNotifier) {
                    return TextField(
                      onTapOutside: (event) {
                        dismissKeyboard();
                      },
                      focusNode: focusNode,
                      autofocus: true,
                      maxLines: 1,
                      buildCounter: (
                        BuildContext context, {
                        required int currentLength,
                        required int? maxLength,
                        required bool isFocused,
                      }) =>
                          const SizedBox.shrink(),
                      maxLength: 200,
                      cursorHeight: 26,
                      scrollPadding: const EdgeInsets.all(0),
                      controller: textEditingController,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsetsDirectional.only(top: 10),
                        isCollapsed: true,
                        hintText: hintText,
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: LinagoraRefColors.material().neutral[60],
                            ),
                      ),
                    );
                  }
                  return Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  );
                },
              ),
            ),
            ValueListenableBuilder(
              valueListenable: searchModeNotifier,
              builder: (context, searchModeNotifier, child) {
                if (searchModeNotifier) {
                  return TwakeIconButton(
                    onPressed: toggleSearchMode,
                    tooltip: L10n.of(context)!.close,
                    icon: Icons.close,
                    paddingAll: 10.0,
                    margin: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 6.0,
                    ),
                  );
                }
                return TwakeIconButton(
                  icon: Icons.search,
                  onPressed: toggleSearchMode,
                  tooltip: L10n.of(context)!.search,
                  paddingAll: 10.0,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
