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

  final StreamController<List<UnifiedContact>> _controller =
      StreamController<List<UnifiedContact>>.broadcast();

  Future<HiveCollectionToMDatabase> get _db async =>
      _database ?? await getIt.getAsync<HiveCollectionToMDatabase>();

  @override
  Future<List<UnifiedContact>> getAll() async {
    final box = (await _db).unifiedContactsBox;
    final keys = await box.getAllKeys();
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
    await (await _db).unifiedContactsBox.clear();
    await _emit();
  }

  @override
  Stream<List<UnifiedContact>> watch() {
    return Stream<List<UnifiedContact>>.multi((controller) {
      // Subscribe synchronously so no write is missed between the initial
      // emission and the first `listen`.
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      getAll().then<void>(controller.add).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        controller.addError(error, stackTrace);
      });
      controller.onCancel = subscription.cancel;
    });
  }

  Future<void> _emit() async {
    if (_controller.isClosed) return;
    _controller.add(await getAll());
  }

  void dispose() {
    _controller.close();
  }
}
