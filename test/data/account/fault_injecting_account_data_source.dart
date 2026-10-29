import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/datasources/account_client_data_source.dart';

import 'one_shot_fault.dart';

/// Makes `addClientName` throw once, so the failure paths of a login can be
/// tried. It is disarmed unless armed through the constructor, and a test puts
/// it in place by overriding `accountClientDataSourceProvider`.
/// `succeedFirst` lets that many calls through before the failure (1: the
/// second account of a run).
///
/// Everything but `addClientName` goes to [_inner] untouched, so the per-client
/// stages of `disposeAndDeleteStorage` stay in the wrapped source and a retry
/// resumes there.
class FaultInjectingAccountDataSource implements AccountClientDataSource {
  FaultInjectingAccountDataSource(
    this._inner, {
    bool failAddClientNameOnce = false,
    int succeedFirst = 0,
  }) : _addClientName = OneShotFault(
         armed: failAddClientNameOnce,
         succeedFirst: succeedFirst,
       );

  final AccountClientDataSource _inner;
  final OneShotFault _addClientName;

  @override
  Future<void> addClientName(String clientName) async {
    _addClientName.maybeThrow('addClientName($clientName)');
    await _inner.addClientName(clientName);
  }

  @override
  Future<Client> createClient(String clientName) =>
      _inner.createClient(clientName);

  @override
  Future<void> removeClientName(String clientName) =>
      _inner.removeClientName(clientName);

  @override
  Future<void> disposeAndDeleteStorage(Client client) =>
      _inner.disposeAndDeleteStorage(client);
}
