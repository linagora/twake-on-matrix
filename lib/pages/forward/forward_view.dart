import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/forward/forward_message_state.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/pages/forward/recent_chat_list.dart';
import 'package:fluffychat/pages/forward/recent_chat_title.dart';
import 'package:fluffychat/pages/forward/forward_view_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ForwardView extends StatelessWidget {
  final ForwardController controller;

  const ForwardView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(ForwardViewStyle.preferredAppBarSize(context)),
        child: _ForwardAppBar(
          isSearchBarShowNotifier: controller.isSearchBarShowNotifier,
          sendFromRoomId: controller.sendFromRoomId,
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          controller.popScreen();
          return true;
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ForwardViewStyle.paddingBody),
          child: Column(
            children: [
              RecentChatsTitle(
                isShowRecentlyChats:
                    controller.isShowRecentlyChatsNotifier.value,
                toggleRecentChat: () => controller.toggleRecentlyChats(),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: controller.isShowRecentlyChatsNotifier,
                builder: (context, isShowRecentlyChat, child) {
                  if (isShowRecentlyChat) {
                    return RecentChatList(
                      rooms: controller.filteredRoomsForAll,
                      selectedEventsNotifier: controller.selectedEventsNotifier,
                      onSelectedChat: (roomId) =>
                          controller.onSelectChat(roomId),
                      recentChatScrollController:
                          controller.recentChatScrollController,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Align(
        alignment: const Alignment(0.5, 1.1),
        child: _ForwardButton(
          forwardAction: controller.forwardAction,
          selectedEventsNotifier: controller.selectedEventsNotifier,
          forwardMessageNotifier: controller.forwardMessageNotifier,
        ),
      ),
    );
  }
}

class _ForwardButton extends StatelessWidget {
  const _ForwardButton({
    required this.selectedEventsNotifier,
    required this.forwardMessageNotifier,
    required this.forwardAction,
  });

  final ValueNotifier<List<String>> selectedEventsNotifier;

  final void Function() forwardAction;

  final ValueNotifier<Either<Failure, Success>?> forwardMessageNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: selectedEventsNotifier,
      builder: ((context, selectedEvents, child) {
        if (selectedEvents.length != 1) {
          return const SizedBox();
        }

        return child!;
      }),
      child: ValueListenableBuilder<Either<Failure, Success>?>(
        valueListenable: forwardMessageNotifier,
        builder: (context, forwardMessageState, child) {
          if (forwardMessageState == null) {
            return child!;
          } else {
            return forwardMessageState.fold((failure) => child!, (success) {
              if (success is ForwardMessageLoading) {
                return SizedBox(
                  height: ForwardViewStyle.bottomBarHeight,
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: TwakeFloatingActionButton(
                        customIcon:
                            SizedBox(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                );
              } else {
                return const SizedBox();
              }
            });
          }
        },
        child: SizedBox(
          height: ForwardViewStyle.bottomBarHeight,
          child: Align(
            alignment: Alignment.centerRight,
            child: TwakeIconButton(
              size: ForwardViewStyle.iconSendSize,
              onPressed: forwardAction,
              tooltip: L10n.of(context)!.send,
              imagePath: ImagePaths.icSend,
            ),
          ),
        ),
      ),
    );
  }
}

class _ForwardAppBar extends StatelessWidget {
  const _ForwardAppBar({
    required this.isSearchBarShowNotifier,
    this.sendFromRoomId,
  });

  final String? sendFromRoomId;

  final ValueNotifier<bool> isSearchBarShowNotifier;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: ForwardViewStyle.preferredAppBarSize(context),
      surfaceTintColor: Colors.transparent,
      leadingWidth: double.infinity,
      leading: Row(
        children: [
          TwakeIconButton(
            tooltip: L10n.of(context)!.back,
            icon: Icons.arrow_back,
            onPressed: () {
              Matrix.of(context).shareContent = null;
              if (sendFromRoomId != null) {
                context.go('/rooms/$sendFromRoomId');
              }
            },
            paddingAll: 8.0,
            margin: const EdgeInsets.symmetric(vertical: 12.0),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: isSearchBarShowNotifier,
              builder: (context, isSearchBarShow, child) {
                if (isSearchBarShow) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
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
                      decoration: InputDecoration(
                        isCollapsed: true,
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: LinagoraRefColors.material().neutral[60],
                            ),
                      ),
                    ),
                  );
                } else {
                  return Text(
                    L10n.of(context)!.forwardTo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing:
                              ChatAppBarTitleStyle.letterSpacingRoomName,
                        ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      actions: [
        TwakeIconButton(
          icon: Icons.search,
          onPressed: () => isSearchBarShowNotifier.value = true,
          tooltip: L10n.of(context)!.search,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size(double.infinity, 4),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.08),
          height: 1,
        ),
      ),
    );
  }
}
