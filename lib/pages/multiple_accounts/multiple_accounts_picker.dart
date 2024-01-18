import 'package:collection/collection.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:fluffychat/presentation/extensions/multiple_accounts/client_profile_extension.dart';
import 'package:fluffychat/presentation/multiple_account/client_profile_presentation.dart';
import 'package:fluffychat/presentation/multiple_account/twake_chat_presentation_account.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/layouts/agruments/switch_active_account_body_args.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_header_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:linagora_design_flutter/multiple_account/models/twake_presentation_account.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MultipleAccountsPickerController {
  final BuildContext context;

  MultipleAccountsPickerController({
    required this.context,
  });

  MatrixState get _matrixState => Matrix.of(context);

  Future<List<ClientProfilePresentation?>> _getClientProfiles() async {
    final profiles = await Future.wait(
      _matrixState.widget.clients.map((client) async {
        final profileBundle = await client.fetchOwnProfile();
        Logs().d(
          'MultipleAccountsPicker::getProfileBundles() - ClientName - ${client.clientName}',
        );
        Logs().d(
          'MultipleAccountsPicker::getProfileBundles() - UserId - ${client.userID}',
        );
        return ClientProfilePresentation(
          profile: profileBundle,
          client: client,
        );
      }),
    );

    return profiles.toList();
  }

  Future<List<TwakeChatPresentationAccount>> _getMultipleAccounts(
    Client currentActiveClient,
  ) async {
    final profileBundles = await _getClientProfiles();
    return profileBundles
        .where((clientProfile) => clientProfile != null)
        .map(
          (clientProfile) => clientProfile!.toTwakeChatPresentationAccount(
            currentActiveClient,
          ),
        )
        .toList();
  }

  void showMultipleAccountsPicker(
    Client currentActiveClient, {
    required VoidCallback onGoToAccountSettings,
  }) async {
    final multipleAccount = await _getMultipleAccounts(
      currentActiveClient,
    );
    multipleAccount.sort((pre, next) {
      return pre.accountActiveStatus.index
          .compareTo(next.accountActiveStatus.index);
    });
    MultipleAccountPicker.showMultipleAccountPicker(
      accounts: multipleAccount,
      context: context,
      onAddAnotherAccount: _onAddAnotherAccount,
      onGoToAccountSettings: onGoToAccountSettings,
      onSetAccountAsActive: (account) => _onSetAccountAsActive.call(
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

  void _onSetAccountAsActive({
    required List<TwakeChatPresentationAccount> multipleAccounts,
    required TwakePresentationAccount account,
  }) async {
    final client = multipleAccounts
        .firstWhereOrNull(
          (element) => element.accountId == account.accountId,
        )
        ?.clientAccount;
    if (client == null || client == _matrixState.client) return;
    _setActiveClient(client);
  }

  void _onAddAnotherAccount() {
    context.go(
      '/rooms/addaccount',
      extra: const TwakeWelcomeArg(
        twakeIdType: TwakeWelcomeType.otherAccounts,
      ),
    );
  }

  void _setActiveClient(Client newClient) async {
    final result = await _matrixState.setActiveClient(newClient);
    if (result.isSuccess) {
      context.go(
        '/rooms',
        extra: SwitchActiveAccountBodyArgs(
          newActiveClient: newClient,
        ),
      );
    }
  }
}
