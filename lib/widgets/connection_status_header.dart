import 'dart:async';
import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

import '../utils/localized_exception_extension.dart';
import 'matrix.dart';

class ConnectionStatusHeader extends StatefulWidget {
  const ConnectionStatusHeader({super.key, this.connectedWidget});

  final Widget? connectedWidget;

  @override
  ConnectionStatusHeaderState createState() => ConnectionStatusHeaderState();
}

class ConnectionStatusHeaderState extends State<ConnectionStatusHeader> {
  late final StreamSubscription _onSyncSub;
  SyncStatus? _lastStatus;
  bool _lastHideState = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _onSyncSub = Matrix.of(
      context,
    ).client.onSyncStatus.stream.listen(_onStatusUpdate);
  }

  void _onStatusUpdate(SyncStatusUpdate update) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final client = Matrix.of(context).client;
      final hide =
          client.onSync.value != null &&
          update.status != SyncStatus.error &&
          client.prevBatch != null;

      if (_lastStatus != update.status || _lastHideState != hide) {
        setState(() {
          _lastStatus = update.status;
          _lastHideState = hide;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _onSyncSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final status =
        client.onSyncStatus.value ??
        const SyncStatusUpdate(SyncStatus.waitingForResponse);
    final hide =
        client.onSync.value != null &&
        status.status != SyncStatus.error &&
        client.prevBatch != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: hide
          ? (widget.connectedWidget != null
                ? widget.connectedWidget!
                : const SizedBox.shrink())
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
        return ((error?.exception ?? Object()) as Object).toLocalizedString(
          context,
        );
      case SyncStatus.processing:
      case SyncStatus.cleaningUp:
      case SyncStatus.finished:
        return l10n!.synchronizingPleaseWait;
    }
  }
}
