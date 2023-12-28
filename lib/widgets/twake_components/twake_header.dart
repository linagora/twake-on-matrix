import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/presentation/multiple_account/twake_chat_presentation_account.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/show_dialog_mixin.dart';
import 'package:fluffychat/widgets/twake_components/twake_header_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:linagora_design_flutter/multiple_account/models/twake_presentation_account.dart';
import 'package:matrix/matrix.dart';

class TwakeHeader extends StatelessWidget
    with ShowDialogMixin
    implements PreferredSizeWidget {
  final ChatListController controller;

  const TwakeHeader({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      toolbarHeight: TwakeHeaderStyle.toolbarHeight,
      automaticallyImplyLeading: false,
      leadingWidth: TwakeHeaderStyle.leadingWidth,
      title: ValueListenableBuilder(
        valueListenable: controller.selectModeNotifier,
        builder: (context, selectMode, _) {
          return Align(
            alignment: TwakeHeaderStyle.alignment(context),
            child: Row(
              children: [
                Expanded(
                  flex: TwakeHeaderStyle.flexActions,
                  child: Padding(
                    padding: TwakeHeaderStyle.leadingPadding,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: selectMode == SelectMode.select
                              ? controller.onClickClearSelection
                              : null,
                          borderRadius: BorderRadius.circular(
                            TwakeHeaderStyle.closeIconSize,
                          ),
                          child: Icon(
                            Icons.close,
                            size: TwakeHeaderStyle.closeIconSize,
                            color: selectMode == SelectMode.select
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Colors.transparent,
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable:
                              controller.conversationSelectionNotifier,
                          builder: (context, conversationSelection, _) {
                            return Padding(
                              padding: TwakeHeaderStyle.counterSelectionPadding,
                              child: Text(
                                conversationSelection.length.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: selectMode == SelectMode.select
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                          : Colors.transparent,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: TwakeHeaderStyle.flexTitle,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      L10n.of(context)!.chats,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  flex: TwakeHeaderStyle.flexActions,
                  child: Padding(
                    padding: TwakeHeaderStyle.actionsPadding,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () => _displayMultipleAccountPicker(context),
                        child: ValueListenableBuilder(
                          valueListenable: controller.currentProfileNotifier,
                          builder: (context, profile, _) {
                            return Avatar(
                              mxContent: profile.avatarUrl,
                              name: profile.displayName ??
                                  Matrix.of(context).client.userID!.localpart,
                              size: TwakeHeaderStyle.avatarSize,
                              fontSize: TwakeHeaderStyle.avatarFontSizeInAppBar,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      centerTitle: true,
    );
  }

  void _displayMultipleAccountPicker(BuildContext context) async {
    final multipleAccount = await _getMultipleAccount();
    multipleAccount.sort((pre, next) {
      return pre.accountActiveStatus.index
          .compareTo(next.accountActiveStatus.index);
    });
    MultipleAccountPicker.showMultipleAccountPicker(
      accounts: multipleAccount,
      context: context,
      onAddAnotherAccount: controller.onAddAnotherAccount,
      onGoToAccountSettings: controller.onGoToAccountSettings,
      onSetAccountAsActive: (account) => controller.onSetAccountAsActive(
        multipleAccounts: multipleAccount,
        account: account,
      ),
      titleAddAnotherAccount: L10n.of(context)!.addAnotherAccount,
      titleAccountSettings: L10n.of(context)!.accountSettings,
      logoApp: Padding(
        padding: TwakeHeaderStyle.logoAppOfMultiplePadding,
        child: SvgPicture.asset(
          ImagePaths.icTwakeImageLogo,
          width: TwakeHeaderStyle.logoAppOfMultipleWidth,
          height: TwakeHeaderStyle.logoAppOfMultipleHeight,
        ),
      ),
      accountNameStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: LinagoraSysColors.material().onSurface,
          ),
      accountIdStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: LinagoraRefColors.material().tertiary[20],
          ),
      addAnotherAccountStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: LinagoraSysColors.material().onPrimary,
          ),
      titleAccountSettingsStyle:
          Theme.of(context).textTheme.labelLarge!.copyWith(
                color: LinagoraSysColors.material().primary,
              ),
    );
  }

  Future<List<TwakeChatPresentationAccount>> _getMultipleAccount() async {
    final profileBundles = await controller.getProfileBundles();
    return profileBundles
        .where((profileBundle) => profileBundle != null)
        .map(
          (profileBundle) => TwakeChatPresentationAccount(
            clientAccount: profileBundle!.client,
            accountId: profileBundle.profileBundle.userId,
            accountName: profileBundle.profileBundle.displayName ?? '',
            avatar: Avatar(
              mxContent: profileBundle.profileBundle.avatarUrl,
              name: profileBundle.profileBundle.displayName ?? '',
              size: TwakeHeaderStyle.avatarOfMultipleAccountSize,
              fontSize: TwakeHeaderStyle.avatarFontSizeInAppBar,
            ),
            accountActiveStatus: profileBundle.profileBundle.userId ==
                    controller.currentProfileNotifier.value.userId
                ? AccountActiveStatus.active
                : AccountActiveStatus.inactive,
          ),
        )
        .toList();
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(TwakeHeaderStyle.toolbarHeight);
}
