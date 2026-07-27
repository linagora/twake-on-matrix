import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_mobile_view.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_style.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_web_view.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_state.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_view_model.dart';
import 'package:fluffychat/presentation/widget_keys/widget_keys.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';

class TomBootstrapDialog extends ConsumerStatefulWidget {
  final Client client;
  final bool wipe;
  final bool wipeRecovery;

  const TomBootstrapDialog({
    super.key,
    required this.client,
    this.wipe = false,
    this.wipeRecovery = false,
  });

  Future<bool?> show(BuildContext context) => TwakeDialog.showDialogFullScreen(
    builder: () => this,
    barrierColor: TomBootstrapDialogStyle.barrierColor(context),
  );

  @override
  ConsumerState<TomBootstrapDialog> createState() => _TomBootstrapDialogState();
}

class _TomBootstrapDialogState extends ConsumerState<TomBootstrapDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Matrix.of(context).showToMBootstrap.value = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = tomBootstrapViewModelProvider(
      widget.client,
      wipe: widget.wipe,
      wipeRecovery: widget.wipeRecovery,
      twakeSupported: Matrix.of(context).twakeSupported,
    );

    ref.listen(provider, (previous, next) {
      if (previous?.popTick == next.popTick) return;
      _handleStateChange(context, next);
    });

    final state = ref.watch(provider);

    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        const WidthPlatformBreakpoint(
          end: ResponsiveUtils.maxMobileWidth,
        ): SlotLayout.from(
          key: DialogKeys.bootstrapBreakpointMobile.key,
          builder: (_) => TomBootstrapDialogMobileView(
            description: _description(context, state),
          ),
        ),
        const WidthPlatformBreakpoint(
          begin: ResponsiveUtils.minTabletWidth,
        ): SlotLayout.from(
          key: DialogKeys.bootstrapBreakpointWebAndDesktop.key,
          builder: (_) => TomBootstrapDialogWebView(
            description: _description(context, state),
          ),
        ),
      },
    );
  }

  String _description(BuildContext context, TomBootstrapUiState state) {
    return switch (state) {
      TomBootstrapLoadingState() => L10n.of(context)!.backingUpYourMessage,
      TomBootstrapCheckingRecoveryState() => L10n.of(
        context,
      )!.configureDataEncryption,
      _ => L10n.of(context)!.recoveringYourEncryptedChats,
    };
  }

  void _handleStateChange(BuildContext context, TomBootstrapUiState state) {
    switch (state) {
      case TomBootstrapWipeRecoveryFailedState():
        TwakeSnackBar.show(context, L10n.of(context)!.cannotEnableKeyBackup);
        Matrix.of(context).showToMBootstrap.value = false;
        Navigator.of(context, rootNavigator: false).pop<bool>();
      case TomBootstrapUnlockErrorState():
        Matrix.of(context).showToMBootstrap.value = false;
        Navigator.of(context, rootNavigator: false).pop<bool>(false);
      case TomBootstrapUploadErrorState():
        Matrix.of(context).showToMBootstrap.value = false;
        Navigator.of(context, rootNavigator: false).pop<bool>();
      case TomBootstrapErrorState():
        Matrix.of(context).showToMBootstrap.value = false;
        Navigator.of(context, rootNavigator: false).pop<bool>();
      case TomBootstrapDoneState():
        Matrix.of(context).showToMBootstrap.value = false;
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: false).pop<bool>(true);
        }
      case TomBootstrapNoRecoveryWordsState(:final popValue)
          when popValue != null:
        Navigator.of(context, rootNavigator: false).pop<bool>(popValue);
      default:
        break;
    }
  }
}
