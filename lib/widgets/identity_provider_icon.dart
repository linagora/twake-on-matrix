import 'package:twake_chat/pages/connect/connect_page.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';

class IdentityProviderIcon extends ConsumerStatefulWidget {
  const IdentityProviderIcon({
    super.key,
    required this.identityProvider,
    required this.size,
  });

  final IdentityProvider identityProvider;
  final double size;

  @override
  ConsumerState<IdentityProviderIcon> createState() =>
      _IdentityProviderIconState();
}

class _IdentityProviderIconState extends ConsumerState<IdentityProviderIcon> {
  late final Future<Client> loginClientFuture;

  @override
  void initState() {
    super.initState();
    loginClientFuture = ref.read(loginSessionsProvider).loginClient();
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
