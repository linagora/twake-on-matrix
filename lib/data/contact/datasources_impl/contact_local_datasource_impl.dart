import 'dart:async';

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

  // Not a Matrix ID: metadata stays in the same ordered Hive log as contacts.
  static const _ownerKey = '__contact_store_owner__';

  final StreamController<List<UnifiedContact>> _controller =
      StreamController<List<UnifiedContact>>.broadcast();

  Future<HiveCollectionToMDatabase> get _db async =>
      _database ?? await getIt.getAsync<HiveCollectionToMDatabase>();

  @override
  Future<List<UnifiedContact>> getAll() async {
    final box = (await _db).unifiedContactsBox;
    final keys = await box.getAllKeys();
    keys.remove(_ownerKey);
    final values = await box.getAll(keys);

    final contacts = <UnifiedContact>[];
    for (final value in values) {
      if (value == null) continue;
      contacts.add(UnifiedContactHiveObj.fromJson(copyMap(value)).toEntity());
    }
    return contacts;
  }

  @override
  Future<UnifiedContact?> getByMatrixId(String matrixId) async {
    final value = await (await _db).unifiedContactsBox.get(matrixId);
    if (value == null) return null;
    return UnifiedContactHiveObj.fromJson(copyMap(value)).toEntity();
  }

  @override
  Future<void> upsert(UnifiedContact contact) async {
    await (await _db).unifiedContactsBox.put(
      contact.matrixId,
      contact.toHiveObj().toJson(),
    );
    await _emit();
  }

  @override
  Future<void> upsertAll(Iterable<UnifiedContact> contacts) async {
    final box = (await _db).unifiedContactsBox;
    for (final contact in contacts) {
      await box.put(contact.matrixId, contact.toHiveObj().toJson());
    }
    await _emit();
  }

  @override
  Future<void> delete(String matrixId) async {
    await (await _db).unifiedContactsBox.delete(matrixId);
    await _emit();
  }

  @override
  Future<void> clear() async {
    final box = (await _db).unifiedContactsBox;
    final keys = await box.getAllKeys();
    keys.remove(_ownerKey);
    await box.deleteAll(keys);
    await _emit();
  }

  @override
  Future<void> prepareForAccount(String? owner) async {
    final database = await _db;
    if (_controller.isClosed) return;
    final box = database.unifiedContactsBox;
    final previousOwner = await box.get(_ownerKey);
    if (_controller.isClosed) return;
    if (owner != null && previousOwner?['owner'] == owner) return;

    // Remove ownership before clearing: interruption can leave an unowned or
    // empty store, never another account's contacts labelled as this account.
    await box.delete(_ownerKey);
    if (_controller.isClosed) return;
    await box.clear();
    if (_controller.isClosed) return;
    if (owner != null) await box.put(_ownerKey, {'owner': owner});
    await _emit();
  }

  @override
  Stream<List<UnifiedContact>> watch() {
    return Stream<List<UnifiedContact>>.multi((controller) {
      var receivedUpdate = false;
      // Subscribe synchronously so no write is missed between the initial
      // emission and the first `listen`.
      final subscription = _controller.stream.listen(
        (contacts) {
          receivedUpdate = true;
          controller.add(contacts);
        },
        onError: controller.addError,
        onDone: controller.close,
      );
      bool canEmit() => !_controller.isClosed && !controller.isClosed;
      getAll()
          .then<void>((contacts) {
            if (canEmit() && !receivedUpdate) controller.add(contacts);
          })
          .catchError((Object error, StackTrace stackTrace) {
            if (canEmit() && !receivedUpdate) {
              controller.addError(error, stackTrace);
            }
          });
      controller.onCancel = subscription.cancel;
    });
  }

  Future<void> _emit() async {
    if (_controller.isClosed) return;
    final contacts = await getAll();
    if (!_controller.isClosed) _controller.add(contacts);
  }

  void dispose() {
    _controller.close();
  }
}
