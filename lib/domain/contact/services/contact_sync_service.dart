import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/sources/contact_enricher.dart';
import 'package:twake_chat/domain/contact/sources/phonebook_resolver.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';

/// Groups the contact use cases to keep the service constructor small.
class ContactUseCases {
  const ContactUseCases({
    required this.sync,
    required this.watch,
    required this.get,
    required this.add,
  });

  final SyncContactsUseCase sync;
  final WatchUnifiedContactsUseCase watch;
  final GetUnifiedContactUseCase get;
  final AddContactUseCase add;
}

/// Optional collaborators of [ContactSyncService].
class ContactSyncOptions {
  const ContactSyncOptions({
    this.enrichers = const <ContactEnricher>[],
    this.phonebookResolver,
    this.isAccountActive,
  });

  /// Second-pass operations run after every sync (TOM `user_info`, …).
  final List<ContactEnricher> enrichers;

  /// Associates the device phonebook with Matrix IDs, on request.
  final PhonebookResolver? phonebookResolver;

  /// Whether the service's account is still the one the app works with. The
  /// sources and enrichers follow the *active* account, so a refresh that
  /// outlives an account switch must stop instead of mixing the accounts.
  final bool Function()? isAccountActive;
}

/// Centralises every contact operation of one account.
///
/// Pure Dart orchestration: it delegates to the use cases and the repository
/// and never talks to an external system directly. Controllers and legacy
/// consumers must go through it instead of reaching into managers or the SDK.
///
/// Everything that writes the store (refresh, manual add, clear) runs one at a
/// time, in call order, so a sync can never overwrite a newer write, and a
/// [clear] always wins over the refresh it interrupts.
class ContactSyncService {
  ContactSyncService({
    required String userId,
    required UnifiedContactRepository repository,
    required ContactResolutionPolicy policy,
    required ContactUseCases useCases,
    ContactSyncOptions options = const ContactSyncOptions(),
  }) : _userId = userId,
       _repository = repository,
       _policy = policy,
       _useCases = useCases,
       _options = options;

  /// Matrix ID of the account that owns the contacts this service operates on.
  final String _userId;
  final UnifiedContactRepository _repository;
  final ContactResolutionPolicy _policy;
  final ContactUseCases _useCases;
  final ContactSyncOptions _options;

  Future<void> _lastWrite = Future<void>.value();
  Future<void>? _refresh;
  bool _refreshResolvesPhonebook = false;

  /// Bumped by [clear]: a refresh started before it must not write afterwards.
  int _generation = 0;

  /// Local-first: callers should render the current store immediately and let
  /// [refresh] run in the background.
  Future<void> initialSync() => refresh();

  /// Fetches every source and enriches the result.
  ///
  /// Concurrent calls share the refresh in progress. [resolvePhonebook] first
  /// associates the device phonebook with Matrix IDs (identity lookup +
  /// address book upload). It is opt-in: only the caller that knows the
  /// phonebook is readable (mobile, permission granted) asks for it, so a
  /// background refresh never triggers the lookup.
  Future<void> refresh({bool resolvePhonebook = false}) {
    final running = _refresh;
    if (running != null && (!resolvePhonebook || _refreshResolvesPhonebook)) {
      return running;
    }

    final generation = _generation;
    _refreshResolvesPhonebook = resolvePhonebook;
    late final Future<void> refresh;
    refresh = _enqueue(() => _runRefresh(resolvePhonebook, generation))
        .whenComplete(() {
          if (identical(_refresh, refresh)) _refresh = null;
        });
    return _refresh = refresh;
  }

  Future<void> _runRefresh(bool resolvePhonebook, int generation) async {
    bool isCurrent() =>
        generation == _generation && (_options.isAccountActive?.call() ?? true);

    if (!isCurrent()) return;
    if (resolvePhonebook) await _resolvePhonebook();
    if (!isCurrent()) return;

    await _useCases.sync.execute(_userId, isCurrent: isCurrent);

    for (final enricher in _options.enrichers) {
      if (!isCurrent()) return;
      // Enrichment is best-effort on top of the synced base data: a failing
      // enricher must not abort the refresh nor skip the remaining ones.
      try {
        await enricher.enrich(_userId);
      } catch (exception, stackTrace) {
        Logs().e(
          'ContactSyncService::refresh: enricher failed',
          exception,
          stackTrace,
        );
      }
    }
  }

  Future<void> _resolvePhonebook() async {
    try {
      await _options.phonebookResolver?.resolve(_userId);
    } catch (exception, stackTrace) {
      // Best effort: the sync still reads the last stored resolution.
      Logs().e(
        'ContactSyncService::refresh: phonebook resolution failed',
        exception,
        stackTrace,
      );
    }
  }

  Stream<List<UnifiedContact>> watchContacts() =>
      _useCases.watch.execute(_userId);

  Future<UnifiedContact?> getContact(String matrixId) =>
      _useCases.get.execute(_userId, matrixId);

  Future<void> addContact({
    required String matrixId,
    String? displayName,
    List<String> emails = const <String>[],
    List<String> phones = const <String>[],
  }) => _enqueue(() async {
    final manual = ContactSourceValue(
      kind: ContactSourceKind.manual,
      displayName: displayName,
      emails: emails,
      phones: phones,
      updatedAt: DateTime.now().toUtc(),
    );

    // Retain previously stored source values (synced, phonebook, …) and
    // replace only the manual entry so a later sync does not discard user data.
    final existing = await _repository.getByMatrixId(_userId, matrixId);
    final retained = existing == null
        ? const <ContactSourceValue>[]
        : existing.sources
              .where((v) => v.kind != ContactSourceKind.manual)
              .toList(growable: false);

    final contact = _policy.resolve(
      matrixId: matrixId,
      values: [...retained, manual],
    );
    await _useCases.add.execute(_userId, contact);
  });

  /// Removes every stored contact of the account (logout). Cancels the refresh
  /// in progress: whatever it still fetches is dropped, and the store is wiped
  /// once its last write is done.
  Future<void> clear() {
    _generation++;
    _refresh = null;
    return _enqueue(() => _repository.clear(_userId));
  }

  /// Runs [task] after every previously queued write. A failing task reaches
  /// its caller without blocking the next ones.
  Future<void> _enqueue(Future<void> Function() task) {
    final result = _lastWrite.then((_) => task());
    _lastWrite = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }
}
