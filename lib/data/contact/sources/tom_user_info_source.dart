import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_session.dart';
import 'package:twake_chat/domain/contact/sources/contact_enricher.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';

/// Second-pass enricher fetching the canonical TOM `user_info` profile for the
/// contacts already in the store (directory / LDAP name + avatar).
///
/// Network calls are capped per run and failures are skipped so a single
/// unreachable profile never blocks the refresh.
class TomUserInfoSource implements ContactEnricher {
  TomUserInfoSource({
    required UnifiedContactRepository repository,
    required UserInfoRepository userInfoRepository,
    required ContactResolutionPolicy policy,
    this.maxPerRun = 50,
  }) : _repository = repository,
       _userInfoRepository = userInfoRepository,
       _policy = policy;

  final UnifiedContactRepository _repository;
  final UserInfoRepository _userInfoRepository;
  final ContactResolutionPolicy _policy;
  final int maxPerRun;
  int _nextContact = 0;

  @override
  Future<void> enrich({ContactSyncSession? session}) async {
    if (session?.isActive == false) return;
    final contacts = await _repository.getContacts();
    var attempted = 0;

    final start = contacts.isEmpty ? 0 : _nextContact % contacts.length;
    for (var offset = 0; offset < contacts.length; offset++) {
      if (session?.isActive == false) return;
      if (attempted >= maxPerRun) break;
      final index = (start + offset) % contacts.length;
      final contact = contacts[index];
      _nextContact = (index + 1) % contacts.length;
      if (_alreadyEnriched(contact)) continue;

      attempted++;
      try {
        final userInfo = await _userInfoRepository.getUserInfo(
          Uri.encodeComponent(contact.matrixId),
        );
        if (session?.isActive == false) return;
        Future<void> persist() async {
          final current = await _repository.getByMatrixId(contact.matrixId);
          if (current == null || session?.isActive == false) return;
          final enriched = _policy.resolve(
            matrixId: contact.matrixId,
            values: [
              ...current.sources,
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
          await _repository.upsert(enriched);
        }

        if (session == null) {
          await persist();
        } else {
          await session.mutate(persist);
        }
      } catch (_) {
        // Skip the unreachable profile; the base sync data is kept.
      }
    }
  }

  bool _alreadyEnriched(UnifiedContact contact) => contact.sources.any(
    (source) => source.kind == ContactSourceKind.tomUserInfo,
  );
}
