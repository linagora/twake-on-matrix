import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/call/usecases/join_call_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/leave_call_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/set_call_media_usecase.provider.dart';
import 'package:twake_chat/domain/call/usecases/watch_call_participants_usecase.provider.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
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
    final serviceUrl = ref
        .read(loginHomeserverSummaryProvider)
        ?.callTokenServiceUrl;
    try {
      final room = await joinCall.execute(
        roomId: roomId,
        serviceUrl: serviceUrl,
        isVideo: isVideo,
      );
      if (!ref.mounted) return;
      state = CallState.connected(roomId: roomId, isDirect: room.isDirect);
      _participants = ref
          .read(watchCallParticipantsUseCaseProvider)
          .execute(roomId)
          .listen(_onParticipants);
      if (_isLeaveRequested) await leave();
    } on CallException catch (error) {
      if (!ref.mounted) return;
      state = _isLeaveRequested
          ? const CallState.idle()
          : CallState.failed(roomId: roomId, error: error);
    }
  }

  void _onParticipants(List<CallParticipant> participants) {
    final current = state;
    if (current is! CallConnected) return;
    final hadOthers = current.participants.any((p) => !p.isLocal);
    state = current.copyWith(participants: participants);
    // DECISION.md D14: a direct call ends when the other person leaves.
    if (current.isDirect && hadOthers && participants.every((p) => p.isLocal)) {
      unawaited(leave());
    }
  }

  /// Hanging up is immediate for the user; the membership ends behind it.
  Future<void> leave() async {
    final current = state;
    if (current is CallConnecting) {
      _isLeaveRequested = true;
      return;
    }
    if (current is! CallConnected) return;
    final leaveCall = ref.read(leaveCallUseCaseProvider);
    final participants = _participants;
    _participants = null;
    state = const CallState.idle();
    await participants?.cancel();
    try {
      await leaveCall.execute(current.roomId);
    } on CallException {
      // The delayed leave of the homeserver ends the membership.
    }
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
