import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/call/usecases/decline_call_ring_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/watch_call_rings_usecase.provider.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';
import 'package:twake_chat/pages/call/call_controller.dart';
import 'package:twake_chat/pages/call/call_state.dart';
import 'package:twake_chat/pages/call/incoming/incoming_call_state.dart';
import 'package:twake_chat/utils/logging/log_orchestrator.dart';
import 'package:twake_chat/utils/logging/log_types.dart';

part 'incoming_call_controller.g.dart';

/// The rings of the account, on each change.
@Riverpod(keepAlive: true)
Stream<List<CallRing>> callRings(Ref ref) =>
    ref.watch(watchCallRingsUseCaseProvider).execute();

/// The call that rings this account while the app is open, until it is
/// answered or declined here or elsewhere, or its ring lapses.
@Riverpod(keepAlive: true)
class IncomingCallController extends _$IncomingCallController {
  // Answered or declined here: quiet before the server says so.
  final _handled = <String>{};

  @override
  IncomingCallState build() {
    final rings = ref.watch(callRingsProvider).value ?? const [];
    final call = ref.watch(callControllerProvider);
    _handled.retainWhere((id) => rings.any((ring) => ring.eventId == id));
    return _pick(rings, call);
  }

  IncomingCallState _pick(List<CallRing> rings, CallState call) {
    final roomInCall = switch (call) {
      CallConnecting(:final roomId) || CallConnected(:final roomId) => roomId,
      _ => null,
    };
    for (final ring in rings) {
      if (_handled.contains(ring.eventId) || ring.room.id == roomInCall) {
        continue;
      }
      return IncomingCallState.ringing(
        ring: ring,
        isInCall: roomInCall != null,
      );
    }
    return const IncomingCallState.quiet();
  }

  CallRing? _take() {
    final current = state;
    if (current is! IncomingCallRinging) return null;
    _handled.add(current.ring.eventId);
    state = _pick(
      ref.read(callRingsProvider).value ?? const [],
      ref.read(callControllerProvider),
    );
    return current.ring;
  }

  /// Joins the call, audio only (DECISION.md D15), leaving the call this
  /// device is in. Gives the ring answered, null when nothing rings.
  CallRing? answer() {
    final ring = _take();
    if (ring == null) return null;
    final calls = ref.read(callControllerProvider.notifier);
    // The leave is immediate for the state; its membership ends behind it.
    unawaited(calls.leave());
    unawaited(calls.join(ring.room.id, isVideo: false));
    return ring;
  }

  /// The ring stops here at once, sent or not: the caller is told when it
  /// can be, as in Twake Space Chat.
  Future<void> decline() async {
    final ring = _take();
    if (ring == null) return;
    try {
      await ref.read(declineCallRingUseCaseProvider).execute(ring);
    } on CallException catch (error, stackTrace) {
      LogOrchestrator().log(
        LogEntry(
          message: 'IncomingCallController: decline not sent',
          level: LogLevel.warn,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
