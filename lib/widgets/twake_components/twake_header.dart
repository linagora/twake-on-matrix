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
            child: Row(
              children: [
                if (!TwakeHeaderStyle.isDesktop(context))
                  Expanded(
                    flex: TwakeHeaderStyle.flexActions,
                    child: Padding(
                      padding: TwakeHeaderStyle.leadingPadding,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: onClearSelection,
                            borderRadius: BorderRadius.circular(
                              TwakeHeaderStyle.closeIconSize,
                            ),
                            child: Icon(
                              Icons.close,
                              size: TwakeHeaderStyle.closeIconSize,
                              color: selectMode == SelectMode.select
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : Colors.transparent,
                            ),
                          ),
                          ValueListenableBuilder(
                            valueListenable: conversationSelectionNotifier,
                            builder: (context, conversationSelection, _) {
                              return Padding(
                                padding:
                                    TwakeHeaderStyle.counterSelectionPadding,
                                child: Text(
                                  conversationSelection.length.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: selectMode == SelectMode.select
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                            : Colors.transparent,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  flex: TwakeHeaderStyle.flexTitle,
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
                  Expanded(
                    flex: TwakeHeaderStyle.flexActions,
                    child: Padding(
                      padding: TwakeHeaderStyle.actionsPadding,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            TwakeHeaderStyle.textBorderRadius,
                          ),
                          onTap: openSelectMode,
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
