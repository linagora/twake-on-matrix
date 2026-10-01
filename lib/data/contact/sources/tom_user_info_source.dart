import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/sources/contact_enricher.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';

/// Second-pass enricher fetching the canonical TOM `user_info` profile for the
/// contacts already in the store (directory / LDAP name + avatar).
///
/// Network calls are capped per run — attempts, not just successes, so an
/// all-failure run stays bounded — and failures are logged and skipped so a
/// single unreachable profile never blocks the refresh. A failing profile is
/// retried only after [failureCooldown], so it cannot starve the contacts
/// behind it in the list.
class TomUserInfoSource implements ContactEnricher {
  TomUserInfoSource({
    required UnifiedContactRepository repository,
    required UserInfoRepository userInfoRepository,
    required ContactResolutionPolicy policy,
    this.maxPerRun = 50,
    this.failureCooldown = const Duration(minutes: 5),
  }) : _repository = repository,
       _userInfoRepository = userInfoRepository,
       _policy = policy;

  final UnifiedContactRepository _repository;
  final UserInfoRepository _userInfoRepository;
  final ContactResolutionPolicy _policy;
  final int maxPerRun;
  final Duration failureCooldown;

  /// Last failure per matrixId (in-memory): retried after [failureCooldown].
  final Map<String, DateTime> _lastFailureAt = <String, DateTime>{};

  @override
  Future<void> enrich(String userId) async {
    final contacts = await _repository.getContacts(userId);
    var attempts = 0;
    final now = DateTime.now().toUtc();

    for (final contact in contacts) {
      if (attempts >= maxPerRun) break;
      if (_alreadyEnriched(contact)) continue;
      final lastFailure = _lastFailureAt[contact.matrixId];
      if (lastFailure != null &&
          now.difference(lastFailure) < failureCooldown) {
        continue;
      }

      // Count the attempt before the network call: failures must consume the
      // per-run budget too, otherwise an all-failure run would be unbounded.
      attempts++;
      try {
        final userInfo = await _userInfoRepository.getUserInfo(
          Uri.encodeComponent(contact.matrixId),
        );
        final enriched = _policy.resolve(
          matrixId: contact.matrixId,
          values: [
            ...contact.sources,
            ContactSourceValue(
              kind: ContactSourceKind.tomUserInfo,
              displayName: userInfo.displayName,
              avatarUrl: userInfo.avatarUrl,
              emails: userInfo.emails ?? const <String>[],
              phones: userInfo.phones ?? const <String>[],
              updatedAt: DateTime.now().toUtc(),
            ),
          ],
        );
        await _repository.upsert(userId, enriched);
        _lastFailureAt.remove(contact.matrixId);
      } catch (exception, stackTrace) {
        _lastFailureAt[contact.matrixId] = now;
        // Skip the unreachable profile; the base sync data is kept.
        Logs().e(
          'TomUserInfoSource::enrich: user_info fetch failed for '
          '${contact.matrixId}',
          exception,
          stackTrace,
        );
      }
    }
  }

  bool _alreadyEnriched(UnifiedContact contact) => contact.sources.any(
    (source) => source.kind == ContactSourceKind.tomUserInfo,
  );
}
