import 'package:fluffychat/pages/chat/chat_context_menu_actions.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/context_menu/twake_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:matrix/matrix.dart';

mixin LinkifyMixin {
  final ValueNotifier<bool> openingPopupMenu = ValueNotifier(false);

  List<ChatContextMenuActions> get phoneNumberContextMenu => [
        ChatContextMenuActions.copyNumber,
      ];

  List<ContextMenuAction> _mapPopupMenuActionsToContextMenuActions({
    required BuildContext context,
    required List<ChatContextMenuActions> actions,
  }) {
    return actions.map((action) {
      return ContextMenuAction(
        name: action.getTitle(
          context,
        ),
        icon: action.getIconData(),
      );
    }).toList();
  }

  void _handleStateContextMenu() {
    openingPopupMenu.toggle();
  }

  void _handleContextMenuAction({
    required BuildContext context,
    required TapDownDetails tapDownDetails,
    required String number,
  }) async {
    final offset = tapDownDetails.globalPosition;
    final listActions = _mapPopupMenuActionsToContextMenuActions(
      context: context,
      actions: phoneNumberContextMenu,
    );
    final selectedActionIndex = await showTwakeContextMenu(
      context: context,
      offset: offset,
      listActions: listActions,
      onClose: _handleStateContextMenu,
    );
    if (selectedActionIndex != null && selectedActionIndex is int) {
      _handleClickOnContextMenuItem(
        action: phoneNumberContextMenu[selectedActionIndex],
        number: number,
      );
    }
  }

  Future<dynamic> showTwakeContextMenu({
    required List<ContextMenuAction> listActions,
    required Offset offset,
    required BuildContext context,
    double? verticalPadding,
    VoidCallback? onClose,
  }) async {
    dynamic result;
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (dialogContext) => TwakeContextMenu(
        dialogContext: dialogContext,
        listActions: listActions,
        position: offset,
        verticalPadding: verticalPadding,
      ),
    ).then((value) {
      result = value;
      onClose?.call();
    });
    return result;
  }

  void _handleClickOnContextMenuItem({
    required ChatContextMenuActions action,
    required String number,
  }) async {
    switch (action) {
      case ChatContextMenuActions.copyNumber:
        Logs().i('LinkifyMixin: handleContextMenuAction: copyNumber $number');
        await Clipboard.setData(ClipboardData(text: number));
        break;
      default:
        break;
    }
  }

  void handleOnTappedLinkHtml({
    required BuildContext context,
    required TapDownDetails details,
    required Link link,
  }) {
    Logs().i(
      'LinkifyMixin: handleOnTappedLink: type: ${link.type} link: ${link.value}',
    );
    switch (link.type) {
      case LinkType.url:
        UrlLauncher(context, url: link.value.toString()).launchUrl();
        break;
      case LinkType.phone:
        _handleContextMenuAction(
          context: context,
          tapDownDetails: details,
          number: link.value.toString(),
        );
        break;
      default:
        Logs().i('LinkifyMixin: handleOnTappedLink: Unhandled link: $link');
        break;
    }
  }

  void dispose() {
    openingPopupMenu.dispose();
  }
}
