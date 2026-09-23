import 'package:twake_chat/data/contact/datasources/contact_local_datasource.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

class UnifiedContactRepositoryImpl implements UnifiedContactRepository {
  const UnifiedContactRepositoryImpl(this._localDataSource);

  final ContactLocalDataSource _localDataSource;

  @override
  Stream<List<UnifiedContact>> watchContacts() => _localDataSource.watch();

  @override
  Future<List<UnifiedContact>> getContacts() => _localDataSource.getAll();

  @override
  Future<UnifiedContact?> getByMatrixId(String matrixId) =>
      _localDataSource.getByMatrixId(matrixId);

  @override
  Future<void> upsert(UnifiedContact contact) =>
      _localDataSource.upsert(contact);

  @override
  Future<void> upsertAll(Iterable<UnifiedContact> contacts) =>
      _localDataSource.upsertAll(contacts);

  @override
  Future<void> delete(String matrixId) => _localDataSource.delete(matrixId);

  @override
  Future<void> clear() => _localDataSource.clear();
}
