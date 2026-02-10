import 'package:fluffychat/pages/connect/connect_page_view_style.dart';
import 'package:fluffychat/widgets/identity_provider_icon.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/connect/connect_page.dart';

class SsoButton extends StatelessWidget {
  final IdentityProvider identityProvider;
  final void Function()? onPressed;
  final Future<Client> loginClientFuture;
  const SsoButton({
    super.key,
    required this.identityProvider,
    this.onPressed,
    required this.loginClientFuture,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: identityProvider.icon == null
                    ? const Icon(Icons.web_outlined)
                    : IdentityProviderIcon(
                        identityProvider: identityProvider,
                        size: ConnectPageViewStyle.iconSize,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              identityProvider.name ??
                  identityProvider.brand ??
                  L10n.of(context)!.singlesignon,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
