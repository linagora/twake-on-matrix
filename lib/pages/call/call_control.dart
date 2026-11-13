import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class CallControl extends StatelessWidget {
  const CallControl({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.isSelected,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final bool? isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onDark = LinagoraSysColors.material().onPrimary;
    return IconButton.filled(
      tooltip: label,
      isSelected: isSelected,
      onPressed: onPressed,
      iconSize: 28,
      style: IconButton.styleFrom(
        backgroundColor: color ?? LinagoraRefColors.material().neutral[30],
        foregroundColor: onDark,
        padding: const EdgeInsets.all(16),
      ),
      icon: Icon(icon),
    );
  }
}
