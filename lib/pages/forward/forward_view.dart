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
import 'package:matrix/matrix.dart';

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
          textEditingController: controller.searchTextEditingController,
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          controller.popScreen();
          return true;
        },
        child: SingleChildScrollView(
          padding:
              const EdgeInsetsDirectional.all(ForwardViewStyle.paddingBody),
          child: Column(
            children: [
              const RecentChatsTitle(),
              ValueListenableBuilder<List<Room>>(
                valueListenable: controller.recentlyChatsNotifier,
                builder: (context, rooms, child) {
                  if (rooms.isNotEmpty) {
                    return RecentChatList(
                      rooms: rooms,
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
      floatingActionButton: ForwardButton(
        forwardAction: controller.forwardAction,
        selectedEventsNotifier: controller.selectedEventsNotifier,
        forwardMessageNotifier: controller.forwardMessageNotifier,
      ),
    );
  }
}

class ForwardButton extends StatelessWidget {
  const ForwardButton({
    super.key,
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
                return const SizedBox(
                  height: ForwardViewStyle.bottomBarHeight,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TwakeFloatingActionButton(
                      customIcon: SizedBox(child: CircularProgressIndicator()),
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
              paddingAll: 0,
              onTap: forwardAction,
              tooltip: L10n.of(context)!.send,
              imagePath: ImagePaths.icSend,
              imageSize: ForwardViewStyle.iconSendSize,
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
    required this.textEditingController,
  });

  final String? sendFromRoomId;

  final ValueNotifier<bool> isSearchBarShowNotifier;

  final TextEditingController textEditingController;

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
            onTap: () {
              Matrix.of(context).shareContent = null;
              if (sendFromRoomId != null) {
                context.go('/rooms/$sendFromRoomId');
              } else {
                context.pop();
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
                      controller: textEditingController,
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
          onTap: () => isSearchBarShowNotifier.value = true,
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
