import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';

part 'switch_ticket.freezed.dart';

/// Names one account switch: the target account and the number of the switch.
/// A handler hands it back to settle that switch and no other.
@freezed
abstract class SwitchTicket with _$SwitchTicket {
  const factory SwitchTicket({required String to, required int seq}) =
      _SwitchTicket;
}

extension SwitchingTicket on Switching {
  SwitchTicket get ticket => SwitchTicket(to: to, seq: seq);
}
