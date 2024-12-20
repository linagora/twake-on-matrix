import 'package:fluffychat/pages/chat/phone_number_context_menu_actions.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/context_menu/twake_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/services.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:matrix/matrix.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:url_launcher/url_launcher.dart';

mixin LinkifyMixin {
  final ValueNotifier<bool> openingPopupMenu = ValueNotifier(false);

  List<PhoneNumberContextMenuActions> get phoneNumberContextMenuOnWeb => [
        PhoneNumberContextMenuActions.copy,
      ];

  List<ContextMenuAction> _mapPopupMenuActionsToContextMenuActions({
    required BuildContext context,
    required List<PhoneNumberContextMenuActions> actions,
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
      actions: phoneNumberContextMenuOnWeb,
    );
    final selectedActionIndex = await showTwakeContextMenu(
      context: context,
      offset: offset,
      listActions: listActions,
      onClose: _handleStateContextMenu,
    );
    if (selectedActionIndex != null && selectedActionIndex is int) {
      _handleClickOnContextMenuItem(
        context: context,
        action: phoneNumberContextMenuOnWeb[selectedActionIndex],
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
    required BuildContext context,
    required PhoneNumberContextMenuActions action,
    required String number,
  }) async {
    switch (action) {
      case PhoneNumberContextMenuActions.copy:
        Logs().i('LinkifyMixin: handleContextMenuAction: copyNumber $number');
        await Clipboard.setData(ClipboardData(text: number));
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.phoneNumberCopiedToClipboard,
        );
        break;
      default:
        break;
    }
  }

  Future<void> _handleShowPullDownMenu({
    required BuildContext context,
    required TapDownDetails tapDownDetails,
    required String number,
  }) {
    return showPullDownMenu(
      context: context,
      items: [
        PullDownMenuItem(
          onTap: () async {
            final phoneUri = Uri(
              scheme: "tel",
              path: number.replaceAll(' ', ''),
            );
            if (await canLaunchUrl(phoneUri)) {
              launchUrl(phoneUri);
            } else {
              Logs().e(
                'LinkifyMixin: handleOnTappedLink: Cannot launch phoneUri: $phoneUri',
              );
            }
          },
          title: L10n.of(context)!.callViaCarrier,
          icon: Icons.call_outlined,
        ),
        PullDownMenuItem(
          title: L10n.of(context)!.copyNumber,
          onTap: () async {
            await Clipboard.setData(
              ClipboardData(text: number),
            );
            TwakeSnackBar.show(
              context,
              L10n.of(context)!.phoneNumberCopiedToClipboard,
            );
          },
          icon: Icons.content_copy_outlined,
        ),
        const PullDownMenuDivider.large(),
        PullDownMenuItem(
          title: number,
          onTap: () {},
          itemTheme: PullDownMenuItemTheme(
            textStyle: context.textTheme.bodyLarge!.copyWith(
              color: LinagoraRefColors.material().neutral[30],
            ),
          ),
        ),
      ],
      position: tapDownDetails.globalPosition & Size.zero,
    );
  }

  void handleOnTappedLinkHtml({
    required BuildContext context,
    required TapDownDetails details,
    required Link link,
  }) async {
    Logs().i(
      'LinkifyMixin: handleOnTappedLink: type: ${link.type} link: ${link.value}',
    );
    switch (link.type) {
      case LinkType.url:
        UrlLauncher(context, url: link.value.toString()).launchUrl();
        break;
      case LinkType.phone:
        if (PlatformInfos.isMobile) {
          _handleShowPullDownMenu(
            context: context,
            tapDownDetails: details,
            number: link.value.toString(),
          );
        } else {
          _handleContextMenuAction(
            context: context,
            tapDownDetails: details,
            number: link.value.toString(),
          );
        }
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
