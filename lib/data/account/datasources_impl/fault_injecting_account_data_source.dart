import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/datasources/account_client_data_source.dart';

/// Debug-only: makes `addClientName` throw once, so the failure paths of a
/// login can be tried by hand or in tests. It is armed with
/// `--dart-define=FAULT_ADD_CLIENT_NAME_ONCE=true`; with
/// `--dart-define=FAULT_ADD_CLIENT_NAME_AFTER=1` the first call succeeds and
/// the second fails (the second account of a device run). In a release build
/// [kDebugMode] is a constant `false`, so the provider never builds this class
/// and it is compiled out.
class FaultInjectingAccountDataSource implements AccountClientDataSource {
  FaultInjectingAccountDataSource(
    this._inner, {
    bool failAddClientNameOnce = const bool.fromEnvironment(
      'FAULT_ADD_CLIENT_NAME_ONCE',
    ),
    int succeedFirst = const int.fromEnvironment('FAULT_ADD_CLIENT_NAME_AFTER'),
  }) : _failAddClientNameOnce = failAddClientNameOnce,
       _succeedFirst = succeedFirst;

  final AccountClientDataSource _inner;
  bool _failAddClientNameOnce;
  int _succeedFirst;

  @override
  Future<void> addClientName(String clientName) async {
    if (_shouldFail()) {
      _failAddClientNameOnce = false;
      Logs().w('FaultInjection: addClientName($clientName) fails once');
      throw StateError('Injected fault: addClientName($clientName)');
    }
    await _inner.addClientName(clientName);
  }

  /// Counts a call down only while the fault is armed.
  bool _shouldFail() {
    if (!kDebugMode || !_failAddClientNameOnce) return false;
    return _succeedFirst-- <= 0;
  }

  @override
  Future<List<Client>> loadClients({required bool initialize}) =>
      _inner.loadClients(initialize: initialize);

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
