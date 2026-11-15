import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/pages/drive_picker/drive_picker_controller.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_picker_state.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_picker_preparation.dart';
import 'package:twake_drive_picker/core.dart'
    show DrivePickOutcome, DrivePickOutcomeCancelled;
import 'package:twake_drive_picker/ui.dart' show DriveIntentWebView;

/// Drive's picker on a full screen, as in the design. Pops with the outcome of
/// the pick; a page left by the system back button counts as a cancel (the
/// caller reads null).
class DrivePickerPage extends ConsumerStatefulWidget {
  const DrivePickerPage({super.key, required this.request});

  final DrivePickerRequest request;

  @override
  ConsumerState<DrivePickerPage> createState() => _DrivePickerPageState();
}

class _DrivePickerPageState extends ConsumerState<DrivePickerPage> {
  DrivePickOutcome? _outcome;
  bool _closed = false;

  /// The view reports the outcome, then asks to close: keep the outcome and pop
  /// once.
  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(_outcome ?? const DrivePickOutcomeCancelled());
  }

  /// Takes this page off the stack, whatever is above it: a sheet opened over
  /// the picker during the account switch must stay, and `pop` would close it.
  void _closeRoute() {
    if (_closed || !mounted) return;
    _closed = true;
    final route = ModalRoute.of(context);
    if (route == null) return;
    Navigator.of(context).removeRoute(route, const DrivePickOutcomeCancelled());
  }

  @override
  Widget build(BuildContext context) {
    // The picker is idle again when the account changed: this page belongs to
    // the old one, so it closes instead of staying on screen.
    ref.listen(drivePickerControllerProvider, (_, state) {
      if (state is DrivePickerIdle) _closeRoute();
    });
    return _guarded(context);
  }

  Widget _guarded(BuildContext context) => PopScope(
    // A page left by the back button is closed: a late request of the view to
    // close it must not pop the screen below.
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) _closed = true;
    },
    child: _page(context),
  );

  Widget _page(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      bottom: false,
      child: DriveIntentWebView(
        intentLoader: widget.request.intentLoader,
        filePickerConfig: widget.request.filePickerConfig,
        platform: widget.request.platform,
        onResult: (outcome) => _outcome = outcome,
        onClose: _close,
      ),
    ),
  );
}
