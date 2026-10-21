import 'package:equatable/equatable.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';

/// Names one account switch: the target account and the number of the switch.
/// A handler hands it back to settle that switch and no other.
final class SwitchTicket extends Equatable {
  final String to;
  final int seq;

  const SwitchTicket({required this.to, required this.seq});

  @override
  List<Object?> get props => [to, seq];
}

extension SwitchingTicket on Switching {
  SwitchTicket get ticket => SwitchTicket(to: to, seq: seq);
}
