import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:fluffychat/widgets/mixins/show_dialog_mixin.dart';
import 'package:fluffychat/widgets/twake_components/twake_header_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class TwakeHeader extends StatelessWidget
    with ShowDialogMixin
    implements PreferredSizeWidget {
  final ValueNotifier<SelectMode> selectModeNotifier;
  final ValueNotifier<List<ConversationSelectionPresentation>>
      conversationSelectionNotifier;
  final VoidCallback openSelectMode;
  final VoidCallback onClearSelection;

  const TwakeHeader({
    Key? key,
    required this.selectModeNotifier,
    required this.openSelectMode,
    required this.conversationSelectionNotifier,
    required this.onClearSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: TwakeHeaderStyle.toolbarHeight,
      automaticallyImplyLeading: false,
      leadingWidth: TwakeHeaderStyle.leadingWidth,
      title: ValueListenableBuilder(
        valueListenable: selectModeNotifier,
        builder: (context, selectMode, _) {
          return Align(
            alignment: TwakeHeaderStyle.alignment(context),
            child: Padding(
              padding: TwakeHeaderStyle.padding,
              child: Row(
                children: [
                  if (selectMode == SelectMode.select)
                    Row(
                      children: [
                        InkWell(
                          onTap: onClearSelection,
                          child: Padding(
                            padding: TwakeHeaderStyle.closeIconPadding,
                            child: Icon(
                              Icons.close,
                              size: TwakeHeaderStyle.closeIconSize,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: conversationSelectionNotifier,
                          builder: (context, conversationSelection, _) {
                            return Text(
                              conversationSelection.length.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            );
                          },
                        ),
                      ],
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        L10n.of(context)!.chats,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ),
                  if (!TwakeHeaderStyle.isDesktop(context))
                    InkWell(
                      borderRadius: BorderRadius.circular(
                        TwakeHeaderStyle.textBorderRadius,
                      ),
                      onTap: openSelectMode,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: TwakeHeaderStyle.textButtonPadding,
                          child: Text(
                            selectMode == SelectMode.normal
                                ? L10n.of(context)!.edit
                                : L10n.of(context)!.done,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(TwakeHeaderStyle.toolbarHeight);
}
