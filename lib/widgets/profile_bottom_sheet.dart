import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:matrix/matrix.dart';

import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/matrix.dart';

class ProfileBottomSheet extends ConsumerWidget {
  final String userId;
  final BuildContext outerContext;

  const ProfileBottomSheet({
    required this.userId,
    required this.outerContext,
    super.key,
  });

  void _startDirectChat(BuildContext context) async {
    final client = Matrix.of(context).client;
    final result = await TwakeDialog.showFutureLoadingDialogFullScreen<String>(
      future: () => client.startDirectChat(userId),
    );
    if (result.error == null) {
      RoomRoute(roomid: result.result!).go(context);
      Navigator.of(context, rootNavigator: false).pop();
      return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref.watch(unifiedContactProvider(userId));
    if (contact != null) {
      return _build(
        context,
        displayName: contact.resolvedDisplayName ?? userId.localpart ?? userId,
        avatarUrl: contact.avatarUrl,
      );
    }

    return FutureBuilder<MatrixUserProfile?>(
      future: ProviderScope.containerOf(
        context,
        listen: false,
      ).read(matrixUserProfileProvider(userId).future),
      builder: (context, snapshot) => _build(
        context,
        displayName: snapshot.data?.displayName ?? userId.localpart ?? userId,
        avatarUrl: snapshot.data?.avatarUrl,
      ),
    );
  }

  Widget _build(
    BuildContext context, {
    required String displayName,
    required String? avatarUrl,
  }) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: CloseButton(
            onPressed: Navigator.of(context, rootNavigator: false).pop,
          ),
          title: ListTile(
            contentPadding: const EdgeInsets.only(right: 16.0),
            title: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
            ),
            subtitle: Text(userId, style: const TextStyle(fontSize: 12)),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton.icon(
                onPressed: () => _startDirectChat(context),
                icon: Icon(Icons.adaptive.share_outlined),
                label: Text(L10n.of(context)!.share),
              ),
            ),
          ],
        ),
        body: ListView(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Avatar(
                  mxContent: avatarUrl == null ? null : Uri.tryParse(avatarUrl),
                  name: displayName,
                  size: AvatarStyle.defaultSize * 3,
                  fontSize: 36,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: FloatingActionButton.extended(
                onPressed: () => _startDirectChat(context),
                label: Text(L10n.of(context)!.newChat),
                icon: const Icon(Icons.send_outlined),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
