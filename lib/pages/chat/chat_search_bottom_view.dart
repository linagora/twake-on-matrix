import 'package:fluffychat/domain/app_state/room/chat_room_search_state.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatSearchBottomView extends StatelessWidget {
  final ChatController controller;
  const ChatSearchBottomView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.isSearchingNotifier,
      builder: (context, value, child) {
        return Container(
          decoration: ChatViewStyle.searchBottomViewDecoration(context),
          child: Row(
            children: [
              ValueListenableBuilder(
                valueListenable: controller.searchStatus,
                builder: (context, value, emptyChild) => value.fold(
                  (failure) => emptyChild!,
                  (success) {
                    if (success is ChatRoomSearchInitial ||
                        success is ChatRoomSearchNoResult) {
                      return emptyChild!;
                    }
                    if (success is ChatRoomSearchLoading) {
                      return const Padding(
                        padding: ChatViewStyle.noSearchResultPadding,
                        child: SizedBox.square(
                          dimension: ChatViewStyle.searchLoadingSize,
                          child: CircularProgressIndicator(
                            strokeWidth: ChatViewStyle.searchLoadingStrokeWidth,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
                child: Padding(
                  padding: ChatViewStyle.noSearchResultPadding,
                  child: Text(L10n.of(context)!.noSearchResult),
                ),
              ),
              const Spacer(),
              ValueListenableBuilder(
                valueListenable: controller.canGoUp,
                builder: (context, canGoUp, child) {
                  return TwakeIconButton(
                    tooltip: L10n.of(context)!.previous,
                    icon: Icons.expand_less,
                    iconColor: ChatViewStyle.searchControlColor(
                      context,
                      active: canGoUp,
                    ),
                    onTap: () => controller.goUpSearchResult(context),
                  );
                },
              ),
              ValueListenableBuilder(
                valueListenable: controller.canGoDown,
                builder: (context, canGoDown, child) {
                  return TwakeIconButton(
                    tooltip: L10n.of(context)!.next,
                    icon: Icons.expand_more,
                    onTap: () => controller.goDownSearchResult(context),
                    iconColor: ChatViewStyle.searchControlColor(
                      context,
                      active: canGoDown,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
