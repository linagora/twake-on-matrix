import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/forward/forward_message_state.dart';
import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/pages/forward/recent_chat_list.dart';
import 'package:fluffychat/pages/forward/recent_chat_title.dart';
import 'package:fluffychat/pages/forward/forward_view_style.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_state_layer.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ForwardView extends StatelessWidget {
  final ForwardController controller;

  const ForwardView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: controller.isFullScreen
            ? ForwardViewStyle.preferredSize(context)
            : ForwardViewStyle.maxPreferredSize(context),
        child: ValueListenableBuilder<Either<Failure, Success>?>(
          valueListenable: controller.forwardMessageNotifier,
          builder: (context, forwardMessageState, child) {
            return SearchableAppBar(
              toolbarHeight: ForwardViewStyle.maxToolbarHeight(context),
              focusNode: controller.searchFocusNode,
              title: L10n.of(context)!.forwardTo,
              searchModeNotifier: controller.isSearchModeNotifier,
              hintText: L10n.of(context)!.searchContacts,
              textEditingController: controller.searchTextEditingController,
              openSearchBar: controller.openSearchBar,
              closeSearchBar: controller.closeSearchBar,
              isFullScreen: controller.isFullScreen,
              displayBackButton: forwardMessageState == null,
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
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
                          selectedChatNotifier:
                              controller.selectedRoomIdNotifier,
                          onSelectedChat: (roomId) =>
                              controller.onToggleSelectChat(roomId),
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
          if (!controller.isFullScreen)
            _WebActionsButton(
              selectedChatNotifier: controller.selectedRoomIdNotifier,
              forwardMessageNotifier: controller.forwardMessageNotifier,
              forwardAction: controller.forwardAction,
            ),
        ],
      ),
      floatingActionButton: controller.isFullScreen
          ? _ForwardButton(
              forwardAction: controller.forwardAction,
              selectedChatNotifier: controller.selectedRoomIdNotifier,
              forwardMessageNotifier: controller.forwardMessageNotifier,
            )
          : null,
    );
  }
}

class _WebActionsButton extends StatelessWidget {
  final ValueNotifier<String> selectedChatNotifier;

  final ValueNotifier<Either<Failure, Success>?> forwardMessageNotifier;

  final void Function() forwardAction;

  const _WebActionsButton({
    required this.selectedChatNotifier,
    required this.forwardMessageNotifier,
    required this.forwardAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ForwardViewStyle.webActionsButtonPadding,
      child: ValueListenableBuilder<String>(
        valueListenable: selectedChatNotifier,
        builder: ((context, selectedChat, child) {
          return ValueListenableBuilder<Either<Failure, Success>?>(
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
                          customIcon:
                              SizedBox(child: CircularProgressIndicator()),
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TwakeTextButton(
                  onTap: () => context.pop(),
                  message: L10n.of(context)!.cancel,
                  borderHover: ForwardViewStyle.webActionsButtonBorder,
                  margin: ForwardViewStyle.webActionsButtonMargin,
                  buttonDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      ForwardViewStyle.webActionsButtonBorder,
                    ),
                  ),
                  styleMessage:
                      Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: LinagoraSysColors.material().primary,
                          ),
                ),
                const SizedBox(width: 8.0),
                TwakeTextButton(
                  onTap: forwardAction,
                  message: L10n.of(context)!.add,
                  margin: ForwardViewStyle.webActionsButtonMargin,
                  borderHover: ForwardViewStyle.webActionsButtonBorder,
                  buttonDecoration: BoxDecoration(
                    color: selectedChat.isNotEmpty
                        ? LinagoraSysColors.material().primary
                        : LinagoraStateLayer(
                            LinagoraSysColors.material().onSurface,
                          ).opacityLayer2,
                    borderRadius: BorderRadius.circular(
                      ForwardViewStyle.webActionsButtonBorder,
                    ),
                  ),
                  styleMessage:
                      Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: selectedChat.isNotEmpty
                                ? LinagoraSysColors.material().onPrimary
                                : LinagoraSysColors.material()
                                    .inverseSurface
                                    .withOpacity(0.6),
                          ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ForwardButton extends StatelessWidget {
  const _ForwardButton({
    required this.selectedChatNotifier,
    required this.forwardMessageNotifier,
    required this.forwardAction,
  });

  final ValueNotifier<String> selectedChatNotifier;

  final void Function() forwardAction;

  final ValueNotifier<Either<Failure, Success>?> forwardMessageNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedChatNotifier,
      builder: ((context, selectedChat, child) {
        if (selectedChat.isEmpty) {
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
