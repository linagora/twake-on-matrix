import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';

class IdentityProviderIcon extends StatelessWidget {
  const IdentityProviderIcon({
    super.key,
    required this.identityProvider,
    required this.size,
  });

  final IdentityProvider identityProvider;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconUri = Uri.tryParse(identityProvider.icon ?? '');

    return MxcImage(
      uri: iconUri,
      width: size,
      height: size,
      fit: BoxFit.contain,
      isThumbnail: true,
      placeholder: (context) => SizedBox.square(dimension: size),
    );
  }
}
