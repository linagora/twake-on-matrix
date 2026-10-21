import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/repositories/account_boot_port.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';

/// Registers the accounts of the boot once; a repository that already knows
/// accounts (a second call, a loaded store) is left as it is.
class AdoptBootAccountsInteractor {
  const AdoptBootAccountsInteractor({
    required AccountRepository repository,
    required AccountBootPort bootPort,
  }) : _repository = repository,
       _bootPort = bootPort;

  final AccountRepository _repository;
  final AccountBootPort _bootPort;

  List<Account> execute({Set<String> pendingRemovals = const {}}) {
    final known = _repository.registeredAccounts();
    if (known.isNotEmpty) return known;
    return _bootPort.adopt(pendingRemovals: pendingRemovals);
  }
}
