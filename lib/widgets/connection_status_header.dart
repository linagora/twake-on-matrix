import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

class ConnectionStatusHeader extends ConsumerStatefulWidget {
  const ConnectionStatusHeader({super.key, this.connectedWidget});

  final Widget? connectedWidget;

  @override
  ConnectionStatusHeaderState createState() => ConnectionStatusHeaderState();
}

class ConnectionStatusHeaderState
    extends ConsumerState<ConnectionStatusHeader> {
  StreamSubscription? _onSyncSub;
  SyncStatusUpdate? _lastStatus;
  bool _lastHideState = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _onSyncSub = ref
        .read(activeMatrixClientProvider)
        ?.onSyncStatus
        .stream
        .listen(_onStatusUpdate);
  }

  void _onStatusUpdate(SyncStatusUpdate update) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final client = ref.read(activeMatrixClientProvider);
      if (client == null) return;
      final hide = client.onSync.value != null && client.prevBatch != null;

      if (_lastStatus?.status != update.status || _lastHideState != hide) {
        setState(() {
          _lastStatus = update;
          _lastHideState = hide;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _onSyncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(activeMatrixClientProvider);
    if (client == null) return const SizedBox.shrink();
    final status =
        _lastStatus ??
        client.onSyncStatus.value ??
        const SyncStatusUpdate(SyncStatus.waitingForResponse);
    final hide = client.onSync.value != null && client.prevBatch != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: hide
          ? widget.connectedWidget ?? const SizedBox.shrink()
          : Text(
              status.toLocalizedString(context),
              key: ValueKey(status.status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LinagoraSysColors.material().secondary,
              ),
            ),
    );
  }
}

extension on SyncStatusUpdate {
  String toLocalizedString(BuildContext context) {
    final l10n = L10n.of(context);
    switch (status) {
      case SyncStatus.waitingForResponse:
        return l10n!.waitingForResponse;
      case SyncStatus.error:
        return l10n!.oopsSomethingWentWrong;
      case SyncStatus.processing:
      case SyncStatus.cleaningUp:
      case SyncStatus.finished:
        return l10n!.synchronizingPleaseWait;
    }
  }
}
