import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class IdentityProviderIcon extends StatefulWidget {
  const IdentityProviderIcon({
    super.key,
    required this.identityProvider,
    required this.size,
  });

  final IdentityProvider identityProvider;
  final double size;

  @override
  State<IdentityProviderIcon> createState() => _IdentityProviderIconState();
}

class _IdentityProviderIconState extends State<IdentityProviderIcon> {
  late final Future<Client> loginClientFuture;

  @override
  void initState() {
    super.initState();
    loginClientFuture = Matrix.of(context).getLoginClient();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loginClientFuture,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.hasError) {
          return Icon(Icons.error_outline, size: widget.size);
        }
        final client = asyncSnapshot.data;
        if (client == null ||
            asyncSnapshot.connectionState != ConnectionState.done) {
          return SizedBox.square(dimension: widget.size);
        }
        return Image.network(
          Uri.parse(
            widget.identityProvider.icon ?? '',
          ).getDownloadLink(client).toString(),
          width: widget.size,
          height: widget.size,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.broken_image, size: widget.size);
          },
        );
      },
    );
  }
}
