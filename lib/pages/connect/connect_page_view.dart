import 'package:fluffychat/pages/connect/connect_page_view_style.dart';
import 'package:fluffychat/widgets/identity_provider_icon.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/widgets/layouts/login_scaffold.dart';
import 'sso_button.dart';

class ConnectPageView extends StatelessWidget {
  final ConnectPageController controller;

  const ConnectPageView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final identityProviders = controller.identityProviders(
      rawLoginTypes: controller.rawLoginTypes,
    );
    final l10n = L10n.of(context)!;
    return LoginScaffold(
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        title: FutureBuilder(
          future: controller.loginClientFuture,
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.hasError) {
              return Text(l10n.oopsSomethingWentWrong);
            }
            return Text(asyncSnapshot.data?.homeserver?.host ?? '');
          },
        ),
      ),
      body: Center(
        child: identityProviders == null
            ? CircularProgressIndicator.adaptive(
                backgroundColor:
                    LinagoraSysColors.material().onTertiaryContainer,
              )
            : identityProviders.length == 1
            ? Container(
                width: double.infinity,
                padding: ConnectPageViewStyle.padding,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                  ),
                  icon: identityProviders.single.icon == null
                      ? const Icon(Icons.web_outlined, size: 16)
                      : IdentityProviderIcon(
                          identityProvider: identityProviders.first,
                          size: ConnectPageViewStyle.iconSize,
                        ),
                  onPressed: () => controller.ssoLoginAction(
                    context: context,
                    id: identityProviders.single.id!,
                  ),
                  label: Text(
                    identityProviders.single.name ??
                        identityProviders.single.brand ??
                        L10n.of(context)!.loginWithOneClick,
                  ),
                ),
              )
            : Wrap(
                children: [
                  for (final identityProvider in identityProviders)
                    SsoButton(
                      onPressed: () => controller.ssoLoginAction(
                        context: context,
                        id: identityProvider.id!,
                      ),
                      identityProvider: identityProvider,
                      loginClientFuture: controller.loginClientFuture,
                    ),
                ].toList(),
              ),
      ),
    );
  }
}
