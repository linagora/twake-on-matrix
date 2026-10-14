import 'package:twake_chat/data/contact/datasources/contact_local_datasource.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

class UnifiedContactRepositoryImpl implements UnifiedContactRepository {
  const UnifiedContactRepositoryImpl(this._localDataSource);

  final ContactLocalDataSource _localDataSource;

  @override
  Stream<List<UnifiedContact>> watchContacts(String userId) =>
      _localDataSource.watch(userId);

  @override
  Future<List<UnifiedContact>> getContacts(String userId) =>
      _localDataSource.getAll(userId);

  @override
  Future<UnifiedContact?> getByMatrixId(String userId, String matrixId) =>
      _localDataSource.getByMatrixId(userId, matrixId);

  @override
  Future<void> upsert(String userId, UnifiedContact contact) =>
      _localDataSource.upsert(userId, contact);

  @override
  Future<void> upsertAll(String userId, Iterable<UnifiedContact> contacts) =>
      _localDataSource.upsertAll(userId, contacts);

  @override
  Future<void> delete(String userId, String matrixId) =>
      _localDataSource.delete(userId, matrixId);

  @override
  Future<void> clear(String userId) => _localDataSource.clear(userId);
}
