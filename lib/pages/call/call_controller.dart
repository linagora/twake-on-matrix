import 'dart:async';

import 'package:collection/collection.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/call/usecases/join_call_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/leave_call_usecase.dart';
import 'package:twake_chat/domain/call/usecases/leave_call_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/set_call_media_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/watch_call_participants_usecase.provider.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/pages/call/call_state.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

part 'call_controller.g.dart';

/// The one call this device is in, whichever screen shows it.
@Riverpod(keepAlive: true)
class CallController extends _$CallController {
  StreamSubscription<List<CallParticipant>>? _participants;
  // Read at join: after an account switch it still holds the joining client.
  LeaveCallUseCase? _leaveCall;
  Future<void>? _cleanup;
  var _isLeaveRequested = false;

  @override
  CallState build() {
    ref.onDispose(() => unawaited(_participants?.cancel()));
    // A call belongs to the account that joined it.
    ref.listen(activeMatrixClientProvider, (_, _) => unawaited(leave()));
    return const CallState.idle();
  }

  Future<void> join(String roomId, {required bool isVideo}) async {
    if (state is CallConnecting || state is CallConnected) return;
    _isLeaveRequested = false;
    state = CallState.connecting(roomId: roomId);
    final joinCall = ref.read(joinCallUseCaseProvider);
    _leaveCall = ref.read(leaveCallUseCaseProvider);
    final serviceUrl = ref
        .read(loginHomeserverSummaryProvider)
        ?.callTokenServiceUrl;
    try {
      // The previous call must not disconnect the media of this one.
      await _cleanup;
      if (!ref.mounted) return;
      final room = await joinCall.execute(
        roomId: roomId,
        serviceUrl: serviceUrl,
        isVideo: isVideo,
        isCancelled: () => _isLeaveRequested,
      );
      if (ref.mounted) await _onJoined(roomId, room);
    } catch (error) {
      if (!ref.mounted) return;
      state = _isLeaveRequested
          ? const CallState.idle()
          : CallState.failed(roomId: roomId, error: _typed(error));
    }
  }

  Future<void> _onJoined(String roomId, CallRoomInfo? room) async {
    if (room == null) {
      state = const CallState.idle();
      return;
    }
    state = CallState.connected(roomId: roomId, isDirect: room.isDirect);
    _participants = ref
        .read(watchCallParticipantsUseCaseProvider)
        .execute(roomId)
        .listen(_onParticipants, onError: _onMediaLost);
    if (_isLeaveRequested) await leave();
  }

  static CallException _typed(Object error) => error is CallException
      ? error
      : CallConnectionFailedException(cause: error);

  void _onParticipants(List<CallParticipant> participants) {
    final current = state;
    if (current is! CallConnected) return;
    state = current.copyWith(participants: participants);
    // DECISION.md D14: a direct call ends when the other person leaves.
    if (!current.isDirect) return;
    if (_hasOtherUser(current.participants) && !_hasOtherUser(participants)) {
      unawaited(leave());
    }
  }

  static bool _hasOtherUser(List<CallParticipant> participants) {
    final me = participants.firstWhereOrNull((p) => p.isLocal)?.userId;
    return participants.any((p) => p.userId != me);
  }

  void _onMediaLost(Object error) {
    final current = state;
    if (current is! CallConnected) return;
    unawaited(
      _end(
        current,
        then: CallState.failed(roomId: current.roomId, error: _typed(error)),
      ),
    );
  }

  /// Hanging up is immediate for the user; the membership ends behind it.
  Future<void> leave() async {
    final current = state;
    if (current is CallConnecting) {
      _isLeaveRequested = true;
      return;
    }
    if (current is! CallConnected) return;
    await _end(current, then: const CallState.idle());
  }

  /// Leaves only if the call of this device is in [roomId].
  Future<void> leaveRoom(String roomId) async {
    final roomInCall = switch (state) {
      CallConnecting(:final roomId) || CallConnected(:final roomId) => roomId,
      _ => null,
    };
    if (roomInCall == roomId) await leave();
  }

  Future<void> _end(CallConnected current, {required CallState then}) {
    final LeaveCallUseCase leaveCall =
        _leaveCall ?? ref.read(leaveCallUseCaseProvider);
    _leaveCall = null;
    final participants = _participants;
    _participants = null;
    state = then;
    return _cleanup = () async {
      await participants?.cancel();
      try {
        await leaveCall.execute(current.roomId);
      } catch (_) {
        // The delayed leave of the homeserver ends the membership.
      }
    }();
  }

  /// False when the device refused the change.
  Future<bool> setMicrophone({required bool isOn}) => _setMedia(
    () => ref.read(setCallMediaUseCaseProvider).execute(isMicrophoneOn: isOn),
  );

  Future<bool> setCamera({required bool isOn}) => _setMedia(
    () => ref.read(setCallMediaUseCaseProvider).execute(isCameraOn: isOn),
  );

  Future<bool> _setMedia(Future<void> Function() change) async {
    if (state is! CallConnected) return false;
    try {
      await change();
      return true;
    } on CallException {
      return false;
    }
  }
}
