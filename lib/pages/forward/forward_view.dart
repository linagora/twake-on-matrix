import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/forward/forward_message_state.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/pages/forward/forward_item.dart';
import 'package:fluffychat/pages/forward/forward_view_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ForwardView extends StatefulWidget {
  final ForwardController controller;

  const ForwardView(this.controller, {super.key});

  @override
  State<ForwardView> createState() => _ForwardViewState();
}

class _ForwardViewState extends State<ForwardView> {
  bool isShowRecentlyChats = true;
  bool isSearchBarShow = false;

  void _toggleRecentlyChats() {
    setState(() {
      isShowRecentlyChats = !isShowRecentlyChats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(ForwardViewStyle.preferredAppBarSize(context)),
        child: _buildAppBarForward(context),
      ),
      body: WillPopScope(
        onWillPop: () async {
          widget.controller.popScreen();
          return true;
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ForwardViewStyle.paddingBody),
          child: Column(
            children: [
              _recentlyChatsTitle(context),
              if (isShowRecentlyChats) _chatList(),
            ],
          ),
        ),
      ),
      floatingActionButton: Align(
        alignment: const Alignment(0.5, 1.1),
        child: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (widget.controller.selectedEvents.length == 1) {
      return ValueListenableBuilder<Either<Failure, Success>?>(
        valueListenable: widget.controller.forwardMessageNotifier,
        builder: (context, forwardMessageNotifier, child) {
          if (forwardMessageNotifier == null) {
            return child!;
          } else {
            return forwardMessageNotifier.fold((failure) => child!, (success) {
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
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: TwakeIconButton(
                size: ForwardViewStyle.iconSendSize,
                onPressed: () => widget.controller.forwardAction(context),
                tooltip: L10n.of(context)!.send,
                imagePath: ImagePaths.icSend,
              ),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAppBarForward(BuildContext context) {
    return AppBar(
      toolbarHeight: ForwardViewStyle.preferredAppBarSize(context),
      surfaceTintColor: Colors.transparent,
      leadingWidth: double.infinity,
      leading: Padding(
        padding: ForwardViewStyle.paddingItemAppbar(context),
        child: Row(
          children: [
            TwakeIconButton(
              tooltip: L10n.of(context)!.back,
              icon: Icons.arrow_back,
              onPressed: () {
                Matrix.of(context).shareContent = null;
                widget.controller.popScreen();
              },
              paddingAll: 8.0,
              margin: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            const SizedBox(width: 8.0),
            isSearchBarShow
                ? Padding(
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
                        hintText: "...",
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: LinagoraRefColors.material().neutral[60],
                            ),
                      ),
                    ),
                  )
                : Text(
                    L10n.of(context)!.forwardTo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing:
                              ChatAppBarTitleStyle.letterSpacingRoomName,
                        ),
                  ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: ForwardViewStyle.paddingItemAppbar(context),
          child: TwakeIconButton(
            icon: Icons.search,
            onPressed: () {},
            tooltip: L10n.of(context)!.search,
          ),
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

  Widget _chatList() {
    final rooms = widget.controller.filteredRoomsForAll;
    if (rooms.isEmpty) {
      const SizedBox();
    } else {
      return ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        controller: widget.controller.forwardListController,
        itemCount: rooms.length,
        itemBuilder: (BuildContext context, int i) {
          return ForwardItem(
            rooms[i],
            key: Key('chat_list_item_${rooms[i].id}'),
            selected: widget.controller.selectedEvents.contains(rooms[i].id),
            onTap: () {
              widget.controller.onSelectChat(rooms[i].id);
            },
          );
        },
      );
    }
    return const SizedBox();
  }

  Widget _recentlyChatsTitle(BuildContext context) {
    return Row(
      children: [
        Text(
          L10n.of(context)!.recentlyChats,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: LinagoraRefColors.material().neutral[40],
              ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TwakeIconButton(
                paddingAll: 6.0,
                buttonDecoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                icon:
                    isShowRecentlyChats ? Icons.expand_less : Icons.expand_more,
                onPressed: () => _toggleRecentlyChats(),
                tooltip: isShowRecentlyChats
                    ? L10n.of(context)!.shrink
                    : L10n.of(context)!.expand,
              ),
            ],
          ),
        )
      ],
    );
  }
}
