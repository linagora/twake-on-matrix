import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';

/// Decides whether an id token can still be sent to the stack. A token that is
/// about to expire counts as expired, so it cannot die between the check and
/// the request.
class IdTokenExpiryPolicy {
  const IdTokenExpiryPolicy({required this.skew});

  /// How long before `expiresAt` a token stops being usable.
  final Duration skew;

  /// True when more than [skew] is left at [now].
  bool isUsable(DriveIdToken token, DateTime now) =>
      token.expiresAt.isAfter(now.add(skew));
}
