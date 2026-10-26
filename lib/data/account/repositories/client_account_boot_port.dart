import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/repositories/account_boot_port.dart';

/// Takes over the clients created and initialised at boot.
class ClientAccountBootPort implements AccountBootPort {
  const ClientAccountBootPort({
    required AccountRepositoryImpl repository,
    required Iterable<Client> clients,
  }) : _repository = repository,
       _clients = clients;

  final AccountRepositoryImpl _repository;
  final Iterable<Client> _clients;

  @override
  List<Account> adopt({required Set<String> pendingRemovals}) =>
      _repository.adopt(_clients, pendingRemovals: pendingRemovals);
}
