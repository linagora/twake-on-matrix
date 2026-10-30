import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/domain/account/entities/client_login_state_event.dart';

/// The accounts a login stores, activates or takes back.
abstract interface class LoginAccounts {
  bool isStored(AccountId id);

  /// Whether the client of [id] holds a session now (`Client.isLogged()`). It
  /// is the state of the client, not of the account list: an account that
  /// logged out stays stored, and a candidate that logged in is not stored
  /// until it is registered.
  bool isLoggedIn(AccountId id);

  Future<void> addAccount(AccountId id);

  /// Removes the stored account [id]: its client is disposed and its storage
  /// deleted first, the bookkeeping is dropped only when that worked. A
  /// failure leaves everything as it was, so the call can be repeated. The
  /// effects of the account that becomes active are the caller's to apply
  /// ([applyEffects]): a removal that worked is never repeated for them.
  Future<void> removeAccount(AccountId id);

  /// Fails when the accounts are not in a state that allows it; the caller has
  /// to await it, or the failure is lost.
  Future<void> logoutLast();

  /// The client that is active now.
  Client get activeClient;

  /// The name of the active client, null when there is none.
  String? get activeClientName;

  Client? clientByName(AccountId id);

  /// Makes [client] the active account; false when it could not be.
  Future<bool> switchTo(Client client);

  /// Runs the effects of [client] becoming the active one.
  Future<void> applyEffects(Client client);

  /// Puts the shared state (ToM, authorization, home server) back to "no
  /// account", for a login that failed when no other account is logged in.
  Future<void> clearEffects();

  Future<void> activateCurrent();

  /// Runs again the removals of logged-out accounts and the discards of
  /// candidates that failed.
  Future<void> retryPendingRemovals();
}

/// The unlogged clients a login runs on: the placeholder and the candidates.
abstract interface class LoginCandidates {
  /// An unlogged client a login screen can use without creating one: the
  /// placeholder of a logged-out boot, or null.
  Client? get reusableClient;

  /// A new unlogged client that is not stored.
  Future<Client> createCandidate();

  /// Disposes the candidate [id] and deletes its storage; it stays known
  /// until that worked, so a failure can be retried.
  Future<void> discardCandidate(AccountId id);

  /// The id of the add-account client the login screens use now.
  String? get pendingCandidateId;

  void setPendingCandidate(AccountId? id);

  /// Ends the session of [id] on the server and locally. A [quiet] sign-out
  /// is not an account logout: the logout handlers of that client skip it.
  Future<void> signOut(AccountId id, {required bool quiet});

  /// Drops the quiet-logout marks of [id].
  void forgetQuiet(AccountId id);

  /// Calls [onState] for each login state of [client].
  StreamSubscription<LoginState> listenLoginState(
    Client client,
    void Function(LoginState state) onState,
  );
}

/// What a stored login sets up, and a rollback undoes.
abstract interface class LoginSetUp {
  Future<void> cancelSubscriptions(AccountId id);

  Future<void> registerSubscriptions(AccountId id);

  /// Deletes the push registration of [id] (the pusher, and the keychain sync
  /// of iOS) while its session is still open; does nothing for a client that
  /// is not logged in. Never throws: a pusher that cannot be deleted is
  /// reported and kept for a retry while the session is open.
  Future<void> removePush(AccountId id);

  /// Saves the ToM and federation configuration; throws when saving fails.
  Future<void> setUpToM(Client client);

  Future<void> setUpFederation(Client client);

  Future<void> syncRecoveryKey(Client client);

  Future<void> setUpAdditionalPush(Client client);

  Future<void> cancelContactSync();

  void reSyncContacts();

  void markFirstSyncDone();
}

/// What the login screens and the error reporting are told.
abstract interface class LoginReporting {
  void emit(ClientLoginStateEvent event);

  /// Makes a failure visible: logged and sent to the error reporting.
  void report(Object error, StackTrace stackTrace, String what);
}

/// What the login sessions need from the app. `MatrixState` implements it
/// through an adapter; tests implement it over the real account repository
/// and notifier.
///
/// It is the union of the roles above, so a part of the login that needs one
/// role can depend on that role only.
abstract interface class LoginHost
    implements LoginAccounts, LoginCandidates, LoginSetUp, LoginReporting {}
