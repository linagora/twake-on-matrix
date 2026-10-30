import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/policy/account_policy.dart';

part 'account_policy.provider.g.dart';

// Kept alive: read by the session-wide accountTransitionsProvider, and a kept-alive
// provider cannot depend on an auto-dispose one.
@Riverpod(keepAlive: true)
AccountPolicy accountPolicy(Ref ref) => const AccountPolicy();
