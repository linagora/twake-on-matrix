import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/sources/contact_enricher.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';

/// Second-pass enricher fetching the canonical TOM `user_info` profile for the
/// contacts already in the store (directory / LDAP name + avatar).
///
/// Network calls are capped per run — attempts, not just successes, so an
/// all-failure run stays bounded — and failures are logged and skipped so a
/// single unreachable profile never blocks the refresh. A failing profile is
/// retried only after [failureCooldown], so it cannot starve the contacts
/// behind it in the list. A profile already stored is refetched once it is
/// older than [refreshAfter], so directory renames eventually show up.
class TomUserInfoSource implements ContactEnricher {
  TomUserInfoSource({
    required UnifiedContactRepository repository,
    required UserInfoRepository userInfoRepository,
    required ContactResolutionPolicy policy,
    String? Function()? activeUserId,
    this.maxPerRun = 50,
    this.failureCooldown = const Duration(minutes: 5),
    this.refreshAfter = const Duration(hours: 24),
  }) : _repository = repository,
       _userInfoRepository = userInfoRepository,
       _policy = policy,
       _activeUserId = activeUserId;

  final UnifiedContactRepository _repository;
  final UserInfoRepository _userInfoRepository;
  final ContactResolutionPolicy _policy;

  /// Account the TOM client is currently configured for. `null` disables the
  /// guard (single-account callers, tests).
  final String? Function()? _activeUserId;

  final int maxPerRun;
  final Duration failureCooldown;
  final Duration refreshAfter;

  /// Last failure per matrixId (in-memory): retried after [failureCooldown].
  final Map<String, DateTime> _lastFailureAt = <String, DateTime>{};

  @override
  Future<void> enrich(String userId) async {
    final contacts = await _repository.getContacts(userId);
    var attempts = 0;
    final now = DateTime.now().toUtc();

    for (final contact in contacts) {
      if (attempts >= maxPerRun) break;
      if (!_needsEnrichment(contact, now)) continue;
      if (!_isActiveAccount(userId)) return;

      // Count the attempt before the network call: failures must consume the
      // per-run budget too, otherwise an all-failure run would be unbounded.
      attempts++;
      await _enrichOne(userId, contact, now);
    }
  }

  /// The ToM client follows the active account: a run started for [userId]
  /// must stop as soon as another account becomes active, otherwise the
  /// profiles of account B would be written into the store of account A.
  bool _isActiveAccount(String userId) {
    final activeUserId = _activeUserId?.call();
    if (activeUserId == null || activeUserId == userId) return true;
    Logs().w(
      'TomUserInfoSource::enrich: skipped, $userId is no longer the active '
      'account ($activeUserId)',
    );
    return false;
  }

  bool _needsEnrichment(UnifiedContact contact, DateTime now) {
    if (!_isStale(contact, now)) return false;
    final lastFailure = _lastFailureAt[contact.matrixId];
    return lastFailure == null ||
        now.difference(lastFailure) >= failureCooldown;
  }

  Future<void> _enrichOne(
    String userId,
    UnifiedContact contact,
    DateTime now,
  ) async {
    try {
      final userInfo = await _userInfoRepository.getUserInfo(
        Uri.encodeComponent(contact.matrixId),
      );
      // Re-check after the await: the account may have switched meanwhile.
      if (!_isActiveAccount(userId)) return;
      await _repository.upsert(userId, _enriched(contact, userInfo, now));
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

  UnifiedContact _enriched(
    UnifiedContact contact,
    UserInfo userInfo,
    DateTime now,
  ) => _policy.resolve(
    matrixId: contact.matrixId,
    values: [
      // Drop the previous user_info snapshot: a refetch replaces it.
      ...contact.sources.where(
        (source) => source.kind != ContactSourceKind.tomUserInfo,
      ),
      ContactSourceValue(
        kind: ContactSourceKind.tomUserInfo,
        displayName: userInfo.displayName,
        avatarUrl: userInfo.avatarUrl,
        emails: userInfo.emails ?? const <String>[],
        phones: userInfo.phones ?? const <String>[],
        updatedAt: now,
      ),
    ],
  );

  /// No user_info value yet, or one older than [refreshAfter] (a value without
  /// timestamp is treated as stale).
  bool _isStale(UnifiedContact contact, DateTime now) {
    for (final source in contact.sources) {
      if (source.kind != ContactSourceKind.tomUserInfo) continue;
      final updatedAt = source.updatedAt;
      return updatedAt == null || now.difference(updatedAt) >= refreshAfter;
    }
    return true;
  }
}
