import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/presentation/extensions/person_presence_extension.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';

/// The presence dot of [userId] on its avatar in a list, kept current by the
/// `/sync`.
class PersonPresenceBadge extends ConsumerWidget {
  const PersonPresenceBadge({
    super.key,
    required this.userId,
    required this.size,
    required this.child,
  });

  final String userId;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = ref.watch(syncedPersonPresenceProvider(userId)).value;
    return LinagoraPresenceBadge(
      presence: presence?.badge,
      size: size,
      child: child,
    );
  }
}
