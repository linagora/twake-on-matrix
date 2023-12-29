import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/show_dialog_mixin.dart';
import 'package:fluffychat/widgets/twake_components/twake_header_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class TwakeHeader extends StatelessWidget
    with ShowDialogMixin
    implements PreferredSizeWidget {
  final ValueNotifier<SelectMode> selectModeNotifier;
  final ValueNotifier<List<ConversationSelectionPresentation>>
      conversationSelectionNotifier;
  final ValueNotifier<Profile> currentProfileNotifier;
  final VoidCallback onClickClearSelection;
  final VoidCallback onClickAvatar;

  const TwakeHeader({
    Key? key,
    required this.selectModeNotifier,
    required this.conversationSelectionNotifier,
    required this.currentProfileNotifier,
    required this.onClickAvatar,
    required this.onClickClearSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: LinagoraSysColors.material().onPrimary,
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
                Expanded(
                  flex: TwakeHeaderStyle.flexActions,
                  child: Padding(
                    padding: TwakeHeaderStyle.leadingPadding,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: selectMode == SelectMode.select
                              ? onClickClearSelection
                              : null,
                          borderRadius: BorderRadius.circular(
                            TwakeHeaderStyle.closeIconSize,
                          ),
                          child: Icon(
                            Icons.close,
                            size: TwakeHeaderStyle.closeIconSize,
                            color: selectMode == SelectMode.select
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Colors.transparent,
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: conversationSelectionNotifier,
                          builder: (context, conversationSelection, _) {
                            return Padding(
                              padding: TwakeHeaderStyle.counterSelectionPadding,
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
                Expanded(
                  flex: TwakeHeaderStyle.flexActions,
                  child: Padding(
                    padding: TwakeHeaderStyle.actionsPadding,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PlatformInfos.isMobile
                          ? InkWell(
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: onClickAvatar,
                              child: ValueListenableBuilder(
                                valueListenable: currentProfileNotifier,
                                builder: (context, profile, _) {
                                  return Avatar(
                                    mxContent: profile.avatarUrl,
                                    name: profile.displayName ??
                                        Matrix.of(context)
                                            .client
                                            .userID!
                                            .localpart,
                                    size: TwakeHeaderStyle.avatarSize,
                                    fontSize:
                                        TwakeHeaderStyle.avatarFontSizeInAppBar,
                                  );
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
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
