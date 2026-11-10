import 'dart:async';

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/call/usecases/join_call_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/leave_call_usecase.dart';
import 'package:twake_chat/domain/call/usecases/leave_call_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/set_call_media_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/watch_call_participants_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/watch_call_room_encrypted_usecase.provider.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/pages/call/call_state.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/logging/log_orchestrator.dart';
import 'package:twake_chat/utils/logging/log_types.dart';

part 'call_controller.g.dart';

/// The one call this device is in, whichever screen shows it.
@Riverpod(keepAlive: true)
class CallController extends _$CallController {
  static const _cleanupWait = Duration(seconds: 10);

  StreamSubscription<List<CallParticipant>>? _participants;
  StreamSubscription<void>? _encryption;
  // Read at join: after an account switch it still holds the joining client.
  LeaveCallUseCase? _leaveCall;
  Future<void>? _cleanup;
  var _isLeaveRequested = false;

  @override
  CallState build() {
    ref.onDispose(() {
      unawaited(_participants?.cancel());
      unawaited(_encryption?.cancel());
    });
    // A call belongs to the account that joined it.
    ref.listen(activeMatrixClientProvider, (_, _) => unawaited(leave()));
    return const CallState.idle();
  }

  Future<void> join(String roomId, {required bool isVideo}) async {
    if (state is CallConnecting || state is CallConnected) return;
    _start(roomId);
    try {
      final room = await _join(roomId, isVideo: isVideo);
      if (ref.mounted) await _onJoined(roomId, room);
    } catch (error, stackTrace) {
      _onJoinFailed(roomId, error, stackTrace);
      // A bug, not a failure of the call: it must reach the crash reports.
      if (error is Error) rethrow;
    }
  }

  void _start(String roomId) {
    _isLeaveRequested = false;
    state = CallState.connecting(roomId: roomId);
    _leaveCall = ref.read(leaveCallUseCaseProvider);
  }

  Future<CallRoomInfo?> _join(String roomId, {required bool isVideo}) async {
    final joinCall = ref.read(joinCallUseCaseProvider);
    final serviceUrl = ref
        .read(loginHomeserverSummaryProvider)
        ?.callTokenServiceUrl;
    // The previous call must not disconnect the media of this one; a
    // homeserver that never answers its leave must not hold this call.
    await _cleanup?.timeout(_cleanupWait, onTimeout: () {});
    if (!ref.mounted) return null;
    return joinCall.execute(
      roomId: roomId,
      serviceUrl: serviceUrl,
      isVideo: isVideo,
      isCancelled: () => _isLeaveRequested,
    );
  }

  void _onJoinFailed(String roomId, Object error, StackTrace stackTrace) {
    _log('join failed', error, stackTrace);
    if (!ref.mounted) return;
    state = _isLeaveRequested
        ? const CallState.idle()
        : CallState.failed(roomId: roomId, error: _typed(error));
  }

  static void _log(String message, Object error, StackTrace? stackTrace) =>
      LogOrchestrator().log(
        LogEntry(
          message: 'CallController: $message',
          level: LogLevel.warn,
          error: error,
          stackTrace: stackTrace,
        ),
      );

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
    // DECISION.md D14: the media of this call is in the clear.
    _encryption = ref
        .read(watchCallRoomEncryptedUseCaseProvider)
        .execute(roomId)
        .listen(
          (_) => _endWith(const CallEncryptionUnsupportedException()),
          onError: (Object error) => _endWith(_typed(error)),
        );
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

  void _endWith(CallException error) {
    final current = state;
    if (current is! CallConnected) return;
    unawaited(
      _end(
        current,
        then: CallState.failed(roomId: current.roomId, error: error),
      ),
    );
  }

  void _onMediaLost(Object error, StackTrace stackTrace) {
    _log('media lost', error, stackTrace);
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
    unawaited(_encryption?.cancel());
    _encryption = null;
    state = then;
    return _cleanup = () async {
      await participants?.cancel();
      try {
        await leaveCall.execute(current.roomId);
      } on Exception catch (error, stackTrace) {
        // The delayed leave of the homeserver ends the membership.
        _log('leave failed', error, stackTrace);
      }
    }();
  }

  /// False when the device refused the change.
  Future<bool> setMicrophone({required bool isOn}) async {
    if (state is! CallConnected) return false;
    try {
      await ref.read(setCallMediaUseCaseProvider).execute(isMicrophoneOn: isOn);
      return true;
    } on CallException {
      return false;
    }
  }
}
