import 'package:fluffychat/domain/app_state/bootstrap/self_verification_state.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_providers.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_state.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_view_model.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_option.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_state.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verify_device_view_model.g.dart';

@riverpod
class VerifyDeviceViewModel extends _$VerifyDeviceViewModel {
  KeyVerification? _request;
  bool _showRecoveryKeyForm = false;
  bool _recoveryKeyVerified = false;
  bool _showResetConfirm = false;
  bool _resetComplete = false;
  bool _isStartingVerification = false;
  bool _isResetting = false;
  bool _retryErrorDismissed = false;
  String? _recoveryKeyError;

  BootstrapViewModel get _bootstrapNotifier =>
      ref.read(bootstrapViewModelProvider(client, wipe: wipe).notifier);

  BootstrapUiState get _bootstrapState =>
      ref.read(bootstrapViewModelProvider(client, wipe: wipe));

  @override
  VerifyDeviceUiState build(Client client, {required bool wipe}) {
    ref.onDispose(_cancelPendingRequest);
    // Keeps ref.watch confined to build (Riverpod 3 requirement) while still
    // reacting to BootstrapViewModel updates — _bootstrapState below reads
    // the current value with ref.read from callback contexts instead.
    ref.listen(bootstrapViewModelProvider(client, wipe: wipe), (_, _) {
      _refresh();
    });
    return _computeState();
  }

  void _cancelPendingRequest() {
    final request = _request;
    if (request == null) return;
    // Detach first so cancel() can't call back into a disposing notifier.
    request.onUpdate = null;
    if (![
      KeyVerificationState.error,
      KeyVerificationState.done,
    ].contains(request.state)) {
      request.cancel('m.user');
    }
  }

  void _refresh() => state = _computeState();

  VerifyDeviceUiState _computeState() {
    if (_recoveryKeyVerified) return const VerifyDeviceSuccessState();

    final bootstrapState = _bootstrapState;
    final retryState = _computeRetryState(bootstrapState);
    if (retryState != null) return retryState;

    if (_resetComplete) return const VerifyDeviceResetCompleteState();
    if (_showResetConfirm) {
      return VerifyDeviceResetConfirmState(isResetting: _isResetting);
    }
    if (_showRecoveryKeyForm) {
      return VerifyDeviceRecoveryKeyFormState(
        initialValue: bootstrapState is BootstrapVerifyDeviceState
            ? bootstrapState.prefilledRecoveryKey
            : null,
        errorText: _recoveryKeyError,
      );
    }

    final request = _request;
    if (request != null) {
      return VerifyDeviceSasState(
        request: request,
        requestState: request.state,
      );
    }

    return VerifyDeviceChooserState(
      isStartingVerification: _isStartingVerification,
    );
  }

  /// Surfaces the outcome of the caller's own "Retry automatically" flow,
  /// read off [BootstrapViewModel]'s state — `null` when there's nothing to
  /// show (no retry ran, or its failure was already dismissed).
  VerifyDeviceUiState? _computeRetryState(BootstrapUiState bootstrapState) {
    if (bootstrapState is! BootstrapVerifyDeviceState) return null;
    if (bootstrapState.retrySucceeded) return const VerifyDeviceSuccessState();
    if (bootstrapState.retryFailed && !_retryErrorDismissed) {
      return const VerifyDeviceRetryErrorState();
    }
    return null;
  }

  void dismissRetryError() {
    _retryErrorDismissed = true;
    _showRecoveryKeyForm = false;
    _showResetConfirm = false;
    _refresh();
  }

  Future<void> startVerification() async {
    if (_isStartingVerification) return;
    _isStartingVerification = true;
    _refresh();
    try {
      final result = await ref
          .read(startSelfVerificationInteractorProvider)
          .execute(client: client)
          .last;
      result.fold((_) {}, (success) {
        if (success is StartSelfVerificationSuccessState) {
          _attachRequest(success.request);
        }
      });
    } catch (error, stackTrace) {
      Logs().e('startVerification failed', error, stackTrace);
    } finally {
      _isStartingVerification = false;
      _refresh();
    }
  }

  void _attachRequest(KeyVerification request) {
    _request = request;
    request.onUpdate = _refresh;
    _refresh();
  }

  /// Drops a finished or failed verification request so the chooser is shown
  /// again, instead of leaving the flow stuck on its terminal state.
  void dismissSasRequest() {
    _request?.onUpdate = null;
    _request = null;
    _refresh();
  }

  void rejectSas() => _request?.rejectSas();

  void acceptSas() => _request?.acceptSas();

  Future<bool> verifyRecoveryKey(String recoveryKey) async {
    final success = await _bootstrapNotifier.unlockWithRecoveryKey(recoveryKey);
    if (success) {
      _recoveryKeyVerified = true;
      _recoveryKeyError = null;
      _refresh();
    }
    return success;
  }

  void setRecoveryKeyError(String message) {
    _recoveryKeyError = message;
    _refresh();
  }

  void showRecoveryKeyForm() {
    _showRecoveryKeyForm = true;
    _refresh();
  }

  void closeRecoveryKeyForm() {
    _showRecoveryKeyForm = false;
    _refresh();
  }

  void showResetConfirm() {
    _showResetConfirm = true;
    _refresh();
  }

  void closeResetConfirm() {
    if (_isResetting) return;
    _showResetConfirm = false;
    _refresh();
  }

  Future<void> resetEncryption(Future<bool> Function() performReset) async {
    if (_isResetting) return;
    _isResetting = true;
    _refresh();
    try {
      final success = await performReset();
      if (success) {
        _resetComplete = true;
      } else {
        _showResetConfirm = false;
      }
    } catch (_) {
      _showResetConfirm = false;
      rethrow;
    } finally {
      _isResetting = false;
      _refresh();
    }
  }

  void retry() {
    _retryErrorDismissed = false;
    _bootstrapNotifier.retry();
  }

  List<VerifyDeviceOption> resolveOptions(List<VerifyDeviceOption> options) {
    return options.map((option) {
      if (option.isUseAnotherDevice) {
        return option.copyWith(
          onTap: startVerification,
          isLoading: _isStartingVerification,
        );
      }
      if (option.isUseRecoveryKey) {
        return option.copyWith(onTap: showRecoveryKeyForm);
      }
      if (option.isNotPossibleToVerify) {
        return option.copyWith(onTap: showResetConfirm);
      }
      return option;
    }).toList();
  }
}
