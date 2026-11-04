import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_controller.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_state.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_view.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';

class SettingsContactsVisibility extends ConsumerStatefulWidget {
  const SettingsContactsVisibility({super.key});

  @override
  ConsumerState<SettingsContactsVisibility> createState() =>
      _SettingsContactsVisibilityScreenState();
}

class _SettingsContactsVisibilityScreenState
    extends ConsumerState<SettingsContactsVisibility> {
  int _loadingDialogOwners = 0;
  bool _isShowingLoadForBuild = false;
  ProviderSubscription<AsyncValue<SettingsContactsVisibilityState>>?
  _visibilitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _visibilitySubscription = ref.listenManual(
        settingsContactsVisibilityControllerProvider,
        _onVisibilityChanged,
        fireImmediately: true,
      );
    });
  }

  @override
  void dispose() {
    _visibilitySubscription?.close();
    super.dispose();
  }

  void _onVisibilityChanged(
    AsyncValue<SettingsContactsVisibilityState>? previous,
    AsyncValue<SettingsContactsVisibilityState> next,
  ) {
    if (next.isLoading) {
      if (_isShowingLoadForBuild) return;
      _isShowingLoadForBuild = true;
      _showLoadingDialog();
      return;
    }
    if (_isShowingLoadForBuild) {
      _isShowingLoadForBuild = false;
      _hideLoadingDialog();
    }
    if (next.hasError && (previous == null || previous.isLoading)) {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.failedToGetContactsVisibility,
      );
    }
  }

  void _showLoadingDialog() {
    if (_loadingDialogOwners++ == 0) TwakeDialog.showLoadingDialog(context);
  }

  void _hideLoadingDialog() {
    if (--_loadingDialogOwners == 0) TwakeDialog.hideLoadingDialog(context);
  }

  Future<void> _update(
    Future<void> Function(SettingsContactsVisibilityController controller)
    update,
  ) async {
    _showLoadingDialog();
    try {
      await update(
        ref.read(settingsContactsVisibilityControllerProvider.notifier),
      );
    } on UpdateUserInfoVisibilityException {
      if (!mounted) return;
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.failedToChangeContactsVisibility,
      );
    } finally {
      if (mounted) _hideLoadingDialog();
    }
  }

  void _onSelectVisibilityOption(SettingsContactsVisibilityEnum option) {
    final current = ref
        .read(settingsContactsVisibilityControllerProvider)
        .value
        ?.visibility;
    if (option == current) return;
    _update((controller) => controller.selectVisibility(option));
  }

  void _onUpdateVisibleFields(VisibleEnum field) {
    _update((controller) => controller.toggleVisibleField(field));
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(settingsContactsVisibilityControllerProvider).value ??
        const SettingsContactsVisibilityState();
    return SettingsContactsVisibilityView(
      state: state,
      onBack: () => const SecurityRoute().go(context),
      onSelectVisibilityOption: _onSelectVisibilityOption,
      onUpdateVisibleFields: _onUpdateVisibleFields,
    );
  }
}
