import 'package:twake_chat/data/presence/datasources/presence_datasource.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/domain/presence/repositories/presence_repository.dart';

class PresenceRepositoryImpl implements PresenceRepository {
  const PresenceRepositoryImpl(this._datasource);

  final PresenceDatasource _datasource;

  @override
  Stream<PersonPresence?> watchPresence(String userId) =>
      _datasource.watchPresence(userId);
}
