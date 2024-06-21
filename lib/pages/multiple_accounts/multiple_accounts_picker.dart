import 'package:collection/collection.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:fluffychat/presentation/multiple_account/twake_chat_presentation_account.dart';
import 'package:fluffychat/widgets/layouts/agruments/switch_active_account_body_args.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_header_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:linagora_design_flutter/multiple_account/models/twake_presentation_account.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

typedef OnGoToAccountSettings = void Function(TwakePresentationAccount account);

class MultipleAccountsPickerController {
  final BuildContext context;
  final List<TwakeChatPresentationAccount> multipleAccounts;

  MultipleAccountsPickerController({
    required this.context,
    required this.multipleAccounts,
  });

  MatrixState get _matrixState => Matrix.of(context);

  void showMultipleAccountsPicker(
    Client currentActiveClient, {
    required VoidCallback onGoToAccountSettings,
  }) async {
    multipleAccounts.sort((pre, next) {
      return pre.accountActiveStatus.index
          .compareTo(next.accountActiveStatus.index);
    });
    MultipleAccountPicker.showMultipleAccountPicker(
      accounts: multipleAccounts,
      context: context,
      onAddAnotherAccount: _onAddAnotherAccount,
      onGoToAccountSettings: onGoToAccountSettings,
      onSetAccountAsActive: (account) => _onSetAccountAsActive(
        multipleAccounts: multipleAccounts,
        account: account,
      ),
      titleAddAnotherAccount: L10n.of(context)!.addAnotherAccount,
      titleAccountSettings: L10n.of(context)!.accountSettings,
      logoApp: Padding(
        padding: TwakeHeaderStyle.logoAppOfMultiplePadding,
        child: Text(
          L10n.of(context)!.selectAccount,
          style: TwakeHeaderStyle.selectAccountTextStyle(context),
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
    await _setActiveClient(client);
  }

  void _onAddAnotherAccount() {
    context.push(
      '/rooms/addaccount',
      extra: const TwakeWelcomeArg(
        twakeIdType: TwakeWelcomeType.otherAccounts,
      ),
    );
  }

  Future<void> _setActiveClient(Client newClient) async {
    final result = await _matrixState.setActiveClient(newClient);
    if (result.isSuccess) {
      _matrixState.reSyncContacts();
      context.go(
        '/rooms',
        extra: SwitchActiveAccountBodyArgs(
          newActiveClient: newClient,
        ),
      );
    }
  }
}
