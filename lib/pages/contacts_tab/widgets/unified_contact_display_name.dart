import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';

/// Displays the resolved name of a contact from the unified store.
///
/// Falls back to [fallback] (then to the raw `matrixId`) when the store has no
/// entry, so it can replace `getProfileFromUserId()`-based labels without a
/// blank state.
class UnifiedContactDisplayName extends ConsumerWidget {
  const UnifiedContactDisplayName({
    super.key,
    required this.matrixId,
    this.fallback,
    this.style,
  });

  final String matrixId;
  final String? fallback;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref.watch(unifiedContactProvider(matrixId));
    final name = contact?.resolvedDisplayName ?? fallback ?? matrixId;
    return Text(name, style: style);
  }
}
