import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/widgets/set_active_client_state.dart';

/// What opening the account of a notification needs from the app state.
abstract class NotificationAccountHost {
  List<Client> get accountClients;

  /// True when the account is active and no switch away from it is running.
  bool isSettledOn(Client target);

  Future<SetActiveClientState> setActiveClient(Client? newClient);

  Future<void> cancelContactsLookup();
}

/// How the account of a notification was reached.
sealed class NotificationAccountOutcome {
  const NotificationAccountOutcome();
}

/// The account is already the active one, or the notification names none.
class NotificationAccountReady extends NotificationAccountOutcome {
  const NotificationAccountReady();
}

/// The switch happened: [client] is the active account.
class NotificationAccountSwitched extends NotificationAccountOutcome {
  const NotificationAccountSwitched(this.client);

  final Client client;
}

/// The switch did not happen: the room of the notification must not be opened
/// on the account that is still active.
class NotificationAccountFailed extends NotificationAccountOutcome {
  const NotificationAccountFailed();
}

/// Makes the account of a tapped notification the active one.
class NotificationAccountSwitch {
  const NotificationAccountSwitch(this._host);

  final NotificationAccountHost _host;

  Future<NotificationAccountOutcome> switchTo(String? receiverId) async {
    if (receiverId == null) return const NotificationAccountReady();
    final target = _host.accountClients.firstWhereOrNull(
      (c) => c.userID == receiverId,
    );
    // Not "the same user as the active client": while a switch away from the
    // account runs, asking for it is what cancels the switch.
    if (target == null || _host.isSettledOn(target)) {
      return const NotificationAccountReady();
    }
    Logs().d('[Push] Switching to account ${target.userID} for notification');
    if (!await _setActive(target)) return const NotificationAccountFailed();
    await _host.cancelContactsLookup();
    return NotificationAccountSwitched(target);
  }

  /// True only when [target] is the active account afterwards.
  Future<bool> _setActive(Client target) async {
    try {
      final result = await _host.setActiveClient(target);
      if (result.isSuccess) return true;
      Logs().w('[Push] Cannot switch to account ${target.clientName}: $result');
    } catch (e, s) {
      Logs().w('[Push] Cannot switch to account ${target.clientName}', e, s);
    }
    return false;
  }
}
