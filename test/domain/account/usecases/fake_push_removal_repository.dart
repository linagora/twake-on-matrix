import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';

class FakePushRemovalRepository extends Fake implements AccountRepository {
  FakePushRemovalRepository({required this.registered, required this.pending});

  final List<Account> registered;
  final Set<String> pending;
  final List<String> cleared = [];
  final Set<String> failing = {};

  @override
  List<Account> registeredAccounts() => registered;

  @override
  Future<Set<String>> pendingPushRemovals() async => pending;

  @override
  Future<void> clearPushRemovalPending(String id) async {
    if (failing.contains(id)) throw StateError(id);
    cleared.add(id);
  }
}
