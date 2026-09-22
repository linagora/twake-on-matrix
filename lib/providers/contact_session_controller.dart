import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart' show Client, Logs;
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

final contactSessionControllerProvider = Provider<ContactSessionController>((
  ref,
) {
  final controller = ContactSessionController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

/// Orders changes to the shared TOM configuration and Hive contact store.
class ContactSessionController {
  ContactSessionController(this._ref);

  final Ref _ref;
  Future<void> _pending = Future<void>.value();
  bool _disposed = false;

  Future<void> transition(
    Client? client,
    Future<void> Function() configure, {
    bool force = false,
  }) {
    final transition = _pending.then((_) async {
      if (_disposed) return;
      if (!force && identical(_ref.read(activeMatrixClientProvider), client)) {
        return;
      }
      final previous = _ref.read(contactSyncServiceProvider);
      final store = _ref.read(contactLocalDataSourceProvider);
      final mutations = _ref.read(contactMutationQueueProvider);
      final userId = client?.userID;
      final homeserver = client?.homeserver;
      final owner = userId == null || homeserver == null
          ? null
          : jsonEncode([homeserver.toString(), userId]);
      previous.dispose();
      _ref.read(activeMatrixClientProvider.notifier).setClient(null);
      await mutations.run(() async {
        if (_disposed) return;
        await store.prepareForAccount(owner);
        if (_disposed) return;
        // Logout configuration may delete the Hive collection itself.
        await configure();
      });
      if (_disposed) return;
      _ref.read(activeMatrixClientProvider.notifier).setClient(client);
      _ref.invalidate(contactSyncServiceProvider);
      if (client != null) {
        unawaited(
          _ref.read(contactSyncServiceProvider).refresh().catchError((
            Object error,
            StackTrace stackTrace,
          ) {
            Logs().e('Contact session refresh failed', error, stackTrace);
          }),
        );
      }
    });
    _pending = transition.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return transition;
  }

  void dispose() => _disposed = true;
}
