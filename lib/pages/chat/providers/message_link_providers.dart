import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/message_link/policy/message_link_policy.provider.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

part 'message_link_providers.g.dart';

/// The matrix.to link copied for [eventId] in [roomId].
@riverpod
String messageLink(
  Ref ref, {
  required String roomId,
  required String eventId,
}) => ref
    .watch(messageLinkPolicyProvider)
    .build(
      roomId: roomId,
      eventId: eventId,
      userId: ref.watch(activeUserIdProvider),
    );
