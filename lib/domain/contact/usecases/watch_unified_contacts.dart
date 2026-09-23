import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

class WatchUnifiedContactsUseCase {
  const WatchUnifiedContactsUseCase(this._repository);

  final UnifiedContactRepository _repository;

  Stream<List<UnifiedContact>> execute() => _repository.watchContacts();
}
