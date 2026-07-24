import 'package:flutter/material.dart';

class VerifyDeviceOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  /// When true, [VerifyDeviceScreen] overrides [onTap] to start an
  /// in-place SAS verification flow instead of using the caller's callback.
  final bool isUseAnotherDevice;

  /// When true, [VerifyDeviceScreen] overrides [onTap] to show the in-place
  /// recovery-key form instead of using the caller's callback.
  final bool isUseRecoveryKey;

  /// When true, [VerifyDeviceScreen] overrides [onTap] to show the in-place
  /// reset-encryption confirmation instead of using the caller's callback.
  final bool isNotPossibleToVerify;

  /// Shows a spinner instead of the trailing chevron and disables [onTap].
  final bool isLoading;

  const VerifyDeviceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isUseAnotherDevice = false,
    this.isUseRecoveryKey = false,
    this.isNotPossibleToVerify = false,
    this.isLoading = false,
  });

  VerifyDeviceOption copyWith({VoidCallback? onTap, bool? isLoading}) {
    return VerifyDeviceOption(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap ?? this.onTap,
      isUseAnotherDevice: isUseAnotherDevice,
      isUseRecoveryKey: isUseRecoveryKey,
      isNotPossibleToVerify: isNotPossibleToVerify,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
