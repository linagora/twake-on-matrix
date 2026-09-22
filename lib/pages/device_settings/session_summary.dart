import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_summary.freezed.dart';

@freezed
sealed class SessionSummary with _$SessionSummary {
  const factory SessionSummary({
    required String deviceName,
    required String lastActiveText,
    required IconData platformIcon,
    required bool verified,
  }) = _SessionSummary;
}

class SessionActions {
  final VoidCallback onChangeName;
  final VoidCallback? onStartVerification;
  final VoidCallback? onRemove;

  const SessionActions({
    required this.onChangeName,
    this.onStartVerification,
    this.onRemove,
  });
}
