import 'package:fluffychat/pages/connect/connect_page_view_style.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/widgets/layouts/login_scaffold.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'sso_button.dart';

class ConnectPageView extends StatelessWidget {
  final ConnectPageController controller;

  const ConnectPageView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final identityProviders =
        controller.identityProviders(rawLoginTypes: controller.rawLoginTypes);
    return LoginScaffold(
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        title: Text(
          Matrix.of(context).getLoginClient().homeserver?.host ?? '',
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
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      icon: identityProviders.single.icon == null
                          ? const Icon(
                              Icons.web_outlined,
                              size: 16,
                            )
                          : Image.network(
                              Uri.parse(identityProviders.single.icon!)
                                  .getDownloadLink(
                                    Matrix.of(context).getLoginClient(),
                                  )
                                  .toString(),
                              width: ConnectPageViewStyle.iconSize,
                              height: ConnectPageViewStyle.iconSize,
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
                        ),
                    ].toList(),
                  ),
      ),
    );
  }
}
