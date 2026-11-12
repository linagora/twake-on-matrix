import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/message_link/policy/message_link_policy.provider.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

part 'message_link_providers.g.dart';

/// The link copied for [eventId] in [roomId]: the web app's link when the
/// homeserver names it (`app.twake.chat` `web_url`), else matrix.to.
@riverpod
String messageLink(
  Ref ref, {
  required String roomId,
  required String eventId,
}) => ref
    .watch(messageLinkPolicyProvider)
    .build(
      webAppOrigin: ref.watch(loginHomeserverSummaryProvider).webAppOrigin,
      roomId: roomId,
      eventId: eventId,
      userId: ref.watch(activeUserIdProvider),
    );
