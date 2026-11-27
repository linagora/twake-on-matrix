import 'package:twake_chat/pages/chat/chat_audio_player_widget.dart';
import 'package:twake_chat/pages/chat_list/browse_public_groups_button.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_list/chat_list_header_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_new_chat_button.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_bar.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_pills.dart';
import 'package:twake_chat/pages/search/search.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/connection_status_header.dart';
import 'package:twake_chat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:twake_chat/widgets/twake_cupertino_page.dart';
import 'package:twake_chat/widgets/twake_components/floating_capsule.dart';
import 'package:twake_chat/widgets/twake_components/twake_header.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatListHeader extends StatelessWidget {
  final ChatListController controller;
  final VoidCallback? onOpenSearchPageInMultipleColumns;

  /// On a phone, the thin search field of the collapsing style, opening the
  /// search of the bottom bar. It shows in what height the header is given
  /// beyond its own, and folds away with it.
  final VoidCallback? onOpenSearch;

  /// False over the search results: the search screen has no folders.
  final bool showFilters;

  const ChatListHeader({
    super.key,
    required this.controller,
    this.onOpenSearchPageInMultipleColumns,
    this.onOpenSearch,
    this.showFilters = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ChatListHeaderStyle.responsive.isMobile(context);
    final appBar = TwakeHeader(
      onClearSelection: controller.onClickClearSelection,
      client: controller.activeClient,
      selectModeNotifier: controller.selectModeNotifier,
      conversationSelectionNotifier: controller.conversationSelectionNotifier,
      onClickAvatar: controller.onClickAvatar,
      connectionStatusHeaderWidget: const ConnectionStatusHeader(),
      actions: [
        if (!isMobile)
          ChatListNewChatButton(controller: controller, isSingleColumn: false),
      ],
    );
    final header = Column(
      children: [
        if (isMobile)
          _PhoneAppBar(controller: controller, appBar: appBar)
        else
          appBar,
        // On a phone the search lives in the bottom bar.
        if (!isMobile)
          Container(
            height: ChatListHeaderStyle.searchBarContainerHeight,
            padding: ChatListHeaderStyle.searchInputPadding,
            child: PlatformInfos.isDesktop
                ? _normalModeWidgetWeb(context)
                : _normalModeWidgetsMobile(context),
          ),
        if (isMobile && onOpenSearch != null)
          Flexible(child: _CollapsingSearchField(onTap: onOpenSearch!)),
        if (showFilters)
          ValueListenableBuilder<SelectMode>(
            valueListenable: controller.selectModeNotifier,
            builder: (context, selectMode, _) => isMobile
                ? RoomListFilterPills(enabled: !selectMode.isSelectMode)
                : RoomListFilterBar(enabled: !selectMode.isSelectMode),
          ),
        // Only show audio player on actual mobile platforms (not just mobile-sized layouts)
        if (isMobile && PlatformInfos.isMobile)
          ChatAudioPlayerWidget(matrix: controller.matrixState),
      ],
    );
    if (!isMobile) return header;
    return ColoredBox(
      color: LinagoraSysColors.material().onPrimary,
      child: header,
    );
  }

  Widget _normalModeWidgetsMobile(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        GestureDetector(
          onTap: () => _navigateWithSlideAnimation(context),
          child: TextField(
            textInputAction: TextInputAction.search,
            enabled: false,
            decoration: ChatListHeaderStyle.searchInputDecoration(context),
          ),
        ),
        // A disabled TextField ignores pointers, so its suffixIcon can't be tapped.
        const Padding(
          padding: EdgeInsetsDirectional.only(end: 4),
          child: BrowsePublicGroupsButton(),
        ),
      ],
    );
  }

  void _navigateWithSlideAnimation(BuildContext context) {
    Navigator.of(
      context,
    ).push(TwakeCupertinoPageRoute(builder: (_) => const Search()));
  }

  Widget _normalModeWidgetWeb(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(
              ChatListHeaderStyle.searchRadiusBorder,
            ),
            onTap: onOpenSearchPageInMultipleColumns,
            child: ValueListenableBuilder(
              valueListenable: controller.matrixState.showToMBootstrap,
              builder: (context, value, _) {
                return TextField(
                  textInputAction: TextInputAction.search,
                  contextMenuBuilder: mobileTwakeContextMenuBuilder,
                  enabled: false,
                  decoration: ChatListHeaderStyle.searchInputDecoration(
                    context,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Laid out whole, shown through the height it is given, from its bottom: it
/// slides under the app bar as the list scrolls.
class _CollapsingSearchField extends StatelessWidget {
  const _CollapsingSearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // Folded away: gone, for a screen reader too.
      builder: (context, box) =>
          box.maxHeight < 1 ? const SizedBox.shrink() : _field(context),
    );
  }

  Widget _field(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        minHeight: ChatListHeaderStyle.collapsingSearchExtent,
        maxHeight: ChatListHeaderStyle.collapsingSearchExtent,
        child: Padding(
          padding: ChatListHeaderStyle.searchInputPadding,
          child: SizedBox(
            key: NavigationKeys.collapsingSearchField.key,
            height: ChatListHeaderStyle.collapsingSearchFieldHeight,
            child: Stack(
              alignment: AlignmentDirectional.centerEnd,
              children: [
                Semantics(
                  container: true,
                  button: true,
                  label: L10n.of(context)!.search,
                  excludeSemantics: true,
                  onTap: onTap,
                  child: GestureDetector(
                    onTap: onTap,
                    child: TextField(
                      enabled: false,
                      decoration: ChatListHeaderStyle.searchInputDecoration(
                        context,
                      ),
                    ),
                  ),
                ),
                // A disabled TextField ignores pointers, so its suffixIcon can't be tapped.
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 4),
                  child: BrowsePublicGroupsButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app bar with the new chat capsule over it, outside it so the app bar
/// does not clip the capsule's shadow.
class _PhoneAppBar extends StatelessWidget {
  const _PhoneAppBar({required this.controller, required this.appBar});

  final ChatListController controller;
  final Widget appBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            appBar,
            PositionedDirectional(
              end: ChatListHeaderStyle.newChatCapsuleEnd,
              bottom: ChatListHeaderStyle.newChatCapsuleBottom,
              child: _NewChatCapsule(controller: controller),
            ),
          ],
        ),
        // The select mode app bar is taller by this gap.
        ValueListenableBuilder<SelectMode>(
          valueListenable: controller.selectModeNotifier,
          builder: (context, selectMode, _) => SizedBox(
            height: selectMode.isSelectMode
                ? 0
                : ChatListHeaderStyle.newChatCapsuleGap,
          ),
        ),
      ],
    );
  }
}

class _NewChatCapsule extends StatelessWidget {
  const _NewChatCapsule({required this.controller});

  final ChatListController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SelectMode>(
      valueListenable: controller.selectModeNotifier,
      builder: (context, selectMode, _) {
        if (selectMode.isSelectMode) return const SizedBox.shrink();
        return SizedBox.square(
          dimension: ChatListHeaderStyle.newChatCapsuleSize,
          child: FloatingCapsule(
            child: ChatListNewChatButton(
              controller: controller,
              isSingleColumn: true,
              color: LinagoraSysColors.material().onSurface,
            ),
          ),
        );
      },
    );
  }
}
