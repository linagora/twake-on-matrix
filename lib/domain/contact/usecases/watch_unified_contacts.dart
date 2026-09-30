import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

class WatchUnifiedContactsUseCase {
  const WatchUnifiedContactsUseCase(this._repository);

  final UnifiedContactRepository _repository;

  /// Streams the contacts owned by account [userId] (its Matrix ID).
  Stream<List<UnifiedContact>> execute(String userId) =>
      _repository.watchContacts(userId);
}
