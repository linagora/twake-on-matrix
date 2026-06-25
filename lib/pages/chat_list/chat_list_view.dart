import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body_view.dart';
import 'package:fluffychat/pages/chat_list/chat_list_bottom_navigator.dart';
import 'package:fluffychat/pages/chat_list/chat_list_bottom_navigator_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header.dart';
import 'package:fluffychat/pages/chat_list/get_started_guide/get_started_guide.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view_style.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ChatListView extends StatelessWidget {
  final ChatListController controller;
  final Widget? bottomNavigationBar;
  final VoidCallback? onOpenSearchPageInMultipleColumns;
  final ChatListBottomNavigatorBarIcon onTapBottomNavigation;

  final responsiveUtils = getIt.get<ResponsiveUtils>();

  ChatListView({
    super.key,
    required this.controller,
    this.bottomNavigationBar,
    this.onOpenSearchPageInMultipleColumns,
    required this.onTapBottomNavigation,
  });

  List<GetStartedStep> _getStartedSteps(BuildContext context) {
    final l10n = L10n.of(context)!;
    return [
      GetStartedStep(
        icon: Icons.sync_outlined,
        title: l10n.getStartedSyncContactsTitle,
        description: l10n.getStartedSyncContactsDescription,
        actionLabel: l10n.getStartedSyncContactsAction,
        onAction: controller.goToNewPrivateChat,
      ),
      GetStartedStep(
        icon: Icons.person_add_alt_1_outlined,
        title: l10n.getStartedInviteTitle,
        description: l10n.getStartedInviteDescription,
        actionLabel: l10n.getStartedInviteAction,
        onAction: controller.goToNewPrivateChat,
      ),
      GetStartedStep(
        icon: Icons.send_outlined,
        title: l10n.getStartedSendMessageTitle,
        description: l10n.getStartedSendMessageDescription,
        actionLabel: l10n.getStartedSendMessageAction,
        onAction: controller.goToNewPrivateChat,
      ),
      GetStartedStep(
        icon: Icons.mark_chat_unread_outlined,
        title: l10n.getStartedReceiveTitle,
        description: l10n.getStartedReceiveDescription,
        actionLabel: '',
      ),
      GetStartedStep(
        icon: Icons.public_outlined,
        title: l10n.getStartedJoinChannelTitle,
        description: l10n.getStartedJoinChannelDescription,
        actionLabel: l10n.getStartedJoinChannelAction,
        onAction: () => controller.goToNewGroupChat(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.matrixState.voiceMessageEvent,
      builder: (context, hasEvent, child) {
        return Scaffold(
          backgroundColor: LinagoraSysColors.material().onPrimary,
          appBar: PreferredSize(
            preferredSize: ChatListViewStyle.preferredSizeAppBar(
              hasAudioEvent: hasEvent != null && PlatformInfos.isMobile,
            ),
            child: ChatListHeader(
              onOpenSearchPageInMultipleColumns:
                  onOpenSearchPageInMultipleColumns,
              controller: controller,
            ),
          ),
          bottomNavigationBar: ValueListenableBuilder(
            valueListenable: controller.conversationSelectionNotifier,
            builder: (context, conversationSelection, __) {
              if (conversationSelection.isNotEmpty) {
                return ChatListBottomNavigator(
                  bottomNavigationActionsWidget: controller
                      .bottomNavigationActionsWidget(
                        paddingIcon: ChatListBottomNavigatorStyle.paddingIcon,
                        iconSize: ChatListBottomNavigatorStyle.iconSize,
                        width: ChatListBottomNavigatorStyle.width,
                      ),
                );
              } else {
                return bottomNavigationBar ?? const SizedBox();
              }
            },
          ),
          body: StreamBuilder<Client>(
            stream: controller.clientStream,
            builder: (context, snapshot) {
              return Column(
                children: [
                  GetStartedGuide(steps: _getStartedSteps(context)),
                  Expanded(child: ChatListBodyView(controller)),
                ],
              );
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: ValueListenableBuilder(
            valueListenable: controller.selectModeNotifier,
            builder: (context, _, __) {
              if (controller.isSelectMode) return const SizedBox();
              return KeyBoardShortcuts(
                keysToPress: {
                  LogicalKeyboardKey.controlLeft,
                  LogicalKeyboardKey.keyN,
                },
                onKeysPressed: () => controller.goToNewPrivateChat(),
                helpLabel: L10n.of(context)!.newChat,
                child: !responsiveUtils.isSingleColumnLayout(context)
                    ? MenuAnchor(
                        menuChildren: [
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.chat),
                            child: Text(
                              L10n.of(context)!.newDirectMessage,
                              style: PopupMenuWidgetStyle.defaultItemTextStyle(
                                context,
                              ),
                            ),
                            onPressed: () => controller.goToNewPrivateChat(),
                          ),
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.group),
                            onPressed: () =>
                                controller.goToNewGroupChat(context),
                            child: Text(
                              L10n.of(context)!.newGroupChat,
                              style: PopupMenuWidgetStyle.defaultItemTextStyle(
                                context,
                              ),
                            ),
                          ),
                        ],
                        style: MenuStyle(
                          alignment: Alignment.topLeft,
                          backgroundColor: WidgetStatePropertyAll(
                            PopupMenuWidgetStyle.defaultMenuColor(context),
                          ),
                        ),
                        builder: (context, menuController, child) {
                          return TwakeFloatingActionButton(
                            icon: Icons.mode_edit_outline_outlined,
                            size: ChatListViewStyle.editIconSize,
                            onTap: () => menuController.open(),
                          );
                        },
                      )
                    : TwakeFloatingActionButton(
                        icon: Icons.mode_edit_outline_outlined,
                        size: ChatListViewStyle.editIconSize,
                        onTap: controller.goToNewPrivateChat,
                      ),
              );
            },
          ),
        );
      },
    );
  }
}
