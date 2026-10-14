import 'dart:async';

import 'package:matrix/matrix.dart' show TupleKey;
import 'package:twake_chat/data/contact/datasources/contact_local_datasource.dart';
import 'package:twake_chat/data/contact/models/unified_contact_hive_obj.dart';
import 'package:twake_chat/data/hive/hive_collection_tom_database.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/utils/copy_map.dart';

class ContactLocalDataSourceImpl implements ContactLocalDataSource {
  ContactLocalDataSourceImpl({HiveCollectionToMDatabase? database})
    : _database = database;

  final HiveCollectionToMDatabase? _database;

  final StreamController<({String userId, List<UnifiedContact> contacts})>
  _controller =
      StreamController<
        ({String userId, List<UnifiedContact> contacts})
      >.broadcast();

  Future<HiveCollectionToMDatabase> get _db async =>
      _database ?? await getIt.getAsync<HiveCollectionToMDatabase>();

  /// Entries are keyed by `userId|matrixId` so several accounts can share the
  /// box without ever seeing each other's contacts (same convention as
  /// `thirdPartyContactsBox`).
  static String _key(String userId, String matrixId) =>
      TupleKey(userId, matrixId).toString();

  static bool _isOwnedBy(String key, String userId) =>
      TupleKey.fromString(key).parts.first == userId;

  @override
  Future<List<UnifiedContact>> getAll(String userId) async {
    final box = (await _db).unifiedContactsBox;
    final keys = await box.getAllKeys();
    final values = await box.getAll([
      for (final key in keys)
        if (_isOwnedBy(key, userId)) key,
    ]);

    final contacts = <UnifiedContact>[];
    for (final value in values) {
      if (value == null) continue;
      try {
        contacts.add(UnifiedContactHiveObj.fromJson(copyMap(value)).toEntity());
      } catch (_) {
        // Skip corrupted entries instead of failing the whole store.
      }
    }
    return contacts;
  }

  @override
  Future<UnifiedContact?> getByMatrixId(String userId, String matrixId) async {
    final value = await (await _db).unifiedContactsBox.get(
      _key(userId, matrixId),
    );
    if (value == null) return null;
    return UnifiedContactHiveObj.fromJson(copyMap(value)).toEntity();
  }

  @override
  Future<void> upsert(String userId, UnifiedContact contact) async {
    await (await _db).unifiedContactsBox.put(
      _key(userId, contact.matrixId),
      contact.toHiveObj().toJson(),
    );
    await _emit(userId);
  }

  @override
  Future<void> upsertAll(
    String userId,
    Iterable<UnifiedContact> contacts,
  ) async {
    final box = (await _db).unifiedContactsBox;
    for (final contact in contacts) {
      await box.put(
        _key(userId, contact.matrixId),
        contact.toHiveObj().toJson(),
      );
    }
    await _emit(userId);
  }

  @override
  Future<void> delete(String userId, String matrixId) async {
    await (await _db).unifiedContactsBox.delete(_key(userId, matrixId));
    await _emit(userId);
  }

  @override
  Future<void> clear(String userId) async {
    final box = (await _db).unifiedContactsBox;
    final keys = [
      for (final key in await box.getAllKeys())
        if (_isOwnedBy(key, userId)) key,
    ];
    await box.deleteAll(keys);
    await _emit(userId);
  }

  @override
  Stream<List<UnifiedContact>> watch(String userId) {
    return Stream<List<UnifiedContact>>.multi((controller) {
      // Subscribe synchronously so no write is missed between the initial
      // emission and the first `listen`. Updates are buffered until the
      // initial snapshot is emitted to preserve ordering.
      var initialized = false;
      final pending = <List<UnifiedContact>>[];
      final subscription = _controller.stream.listen((event) {
        if (event.userId != userId) return;
        if (initialized) {
          controller.add(event.contacts);
        } else {
          pending.add(event.contacts);
        }
      }, onError: controller.addError);
      void flush() {
        initialized = true;
        for (final contacts in pending) {
          controller.add(contacts);
        }
        pending.clear();
      }

      getAll(userId)
          .then<void>((initial) {
            controller.add(initial);
            flush();
          })
          .catchError((Object error, StackTrace stackTrace) {
            controller.addError(error, stackTrace);
            flush();
          });
      controller.onCancel = subscription.cancel;
    });
  }

  Future<void> _emit(String userId) async {
    if (_controller.isClosed) return;
    _controller.add((userId: userId, contacts: await getAll(userId)));
  }

  void dispose() {
    _controller.close();
  }
}
