import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/colors/linagora_state_layer.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/forward/forward.dart';
import 'package:twake_chat/pages/forward/forward_controller.dart';
import 'package:twake_chat/pages/forward/forward_recent_chat_list.dart';
import 'package:twake_chat/pages/forward/forward_state.dart';
import 'package:twake_chat/pages/forward/forward_view_style.dart';
import 'package:twake_chat/pages/forward/recent_chat_title.dart';
import 'package:twake_chat/widgets/app_bars/searchable_app_bar.dart';
import 'package:twake_chat/widgets/twake_components/twake_fab.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';
import 'package:twake_chat/widgets/twake_components/twake_text_button.dart';

class ForwardView extends ConsumerWidget {
  final ForwardScreenState screen;

  const ForwardView(this.screen, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forwardControllerProvider);
    final rooms = screen.recentChats;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: screen.isFullScreen
            ? ForwardViewStyle.preferredSize(context)
            : ForwardViewStyle.maxPreferredSize(context),
        child: SearchableAppBar(
          toolbarHeight: ForwardViewStyle.maxToolbarHeight(context),
          focusNode: screen.searchFocusNode,
          title: L10n.of(context)!.forwardTo,
          searchModeNotifier: screen.isSearchModeNotifier,
          hintText: L10n.of(context)!.searchContacts,
          textEditingController: screen.searchTextEditingController,
          openSearchBar: screen.openSearchBar,
          closeSearchBar: screen.closeSearchBar,
          isFullScreen: screen.isFullScreen,
          displayBackButton: state is! ForwardSending,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(
                ForwardViewStyle.paddingBody,
              ),
              child: Column(
                children: [
                  const RecentChatsTitle(),
                  if (rooms.isNotEmpty)
                    ForwardRecentChatList(
                      rooms: rooms,
                      selectedRoomIds: screen.selectedRoomIds,
                      onSelectedChat: screen.onToggleSelectChat,
                      recentChatScrollController:
                          screen.recentChatScrollController,
                    ),
                ],
              ),
            ),
          ),
          if (!screen.isFullScreen)
            _WebActionsButton(
              state: state,
              hasSelection: screen.selectedRoomIds.isNotEmpty,
              forwardAction: screen.forwardAction,
            ),
        ],
      ),
      floatingActionButton: screen.isFullScreen
          ? _ForwardButton(
              state: state,
              hasSelection: screen.selectedRoomIds.isNotEmpty,
              forwardAction: screen.forwardAction,
            )
          : null,
    );
  }
}

class _SendingIndicator extends StatelessWidget {
  const _SendingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: ForwardViewStyle.bottomBarHeight,
      child: Align(
        alignment: Alignment.centerRight,
        child: TwakeFloatingActionButton(
          customIcon: SizedBox(child: CupertinoActivityIndicator()),
        ),
      ),
    );
  }
}

class _WebActionsButton extends StatelessWidget {
  final ForwardState state;

  final bool hasSelection;

  final void Function() forwardAction;

  const _WebActionsButton({
    required this.state,
    required this.hasSelection,
    required this.forwardAction,
  });

  @override
  Widget build(BuildContext context) {
    final linagoraSysColors = LinagoraSysColors.material();
    return Padding(
      padding: ForwardViewStyle.webActionsButtonPadding,
      child: switch (state) {
        ForwardSending() => const _SendingIndicator(),
        ForwardDone(successCount: > 0) => const SizedBox.shrink(),
        ForwardIdle() || ForwardDone() => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TwakeTextButton(
              onTap: () => Navigator.of(context).pop(),
              message: L10n.of(context)!.cancel,
              borderHover: ForwardViewStyle.webActionsButtonBorder,
              margin: ForwardViewStyle.webActionsButtonMargin,
              buttonDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  ForwardViewStyle.webActionsButtonBorder,
                ),
              ),
              styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: linagoraSysColors.primary,
              ),
            ),
            const SizedBox(width: 8.0),
            TwakeTextButton(
              onTap: hasSelection ? forwardAction : null,
              message: L10n.of(context)!.add,
              margin: ForwardViewStyle.webActionsButtonMargin,
              borderHover: ForwardViewStyle.webActionsButtonBorder,
              buttonDecoration: BoxDecoration(
                color: hasSelection
                    ? linagoraSysColors.primary
                    : LinagoraStateLayer(
                        linagoraSysColors.onSurface,
                      ).opacityLayer2,
                borderRadius: BorderRadius.circular(
                  ForwardViewStyle.webActionsButtonBorder,
                ),
              ),
              styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: hasSelection
                    ? linagoraSysColors.onPrimary
                    : linagoraSysColors.inverseSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      },
    );
  }
}

class _ForwardButton extends StatelessWidget {
  const _ForwardButton({
    required this.state,
    required this.hasSelection,
    required this.forwardAction,
  });

  final ForwardState state;

  final bool hasSelection;

  final void Function() forwardAction;

  @override
  Widget build(BuildContext context) {
    if (!hasSelection) {
      return const SizedBox.shrink();
    }
    return switch (state) {
      ForwardSending() => const _SendingIndicator(),
      ForwardDone(successCount: > 0) => const SizedBox.shrink(),
      ForwardIdle() || ForwardDone() => SizedBox(
        height: ForwardViewStyle.bottomBarHeight,
        child: Align(
          alignment: Alignment.centerRight,
          child: TwakeIconButton(
            paddingAll: 0,
            onTap: forwardAction,
            tooltip: L10n.of(context)!.send,
            imagePath: Assets.images.icSend.path,
            imageSize: ForwardViewStyle.iconSendSize,
          ),
        ),
      ),
    };
  }
}
