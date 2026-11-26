import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:twake_chat/domain/call/usecases/ensure_call_ring_push_rule_usecase.dart';
import 'package:twake_chat/domain/call/usecases/ensure_call_ring_push_rule_usecase.provider.dart';
import 'package:twake_chat/pages/call/call_screen.dart';
import 'package:twake_chat/pages/call/incoming/incoming_call_banner.dart';
import 'package:twake_chat/pages/call/incoming/incoming_call_controller.dart';
import 'package:twake_chat/pages/call/incoming/incoming_call_state.dart';

/// Shows the call that rings over the app, and rings, except during another
/// call (Twake Space Chat D106).
class IncomingCallHost extends ConsumerStatefulWidget {
  const IncomingCallHost({
    required this.navigatorKey,
    required this.child,
    this.createPlayer = AudioPlayer.new,
    super.key,
  });

  static const ringAsset = 'assets/sounds/call_ring.m4a';

  /// Android rings it as a ringtone, so the ringer mode and Do Not Disturb
  /// apply. iOS has no such attribute: the app sets no audio session
  /// category, and the default one follows the silent switch.
  static const ringAttributes = AndroidAudioAttributes(
    contentType: AndroidAudioContentType.sonification,
    usage: AndroidAudioUsage.notificationRingtone,
  );

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  final AudioPlayer Function({bool androidApplyAudioAttributes}) createPlayer;

  @override
  ConsumerState<IncomingCallHost> createState() => _IncomingCallHostState();
}

class _IncomingCallHostState extends ConsumerState<IncomingCallHost> {
  AudioPlayer? _player;
  late final ProviderSubscription<EnsureCallRingPushRuleUseCase> _pushRules;

  @override
  void initState() {
    super.initState();
    // Twake Space Chat D106: once per account, so that its push rings. The
    // use case is rebuilt for each account.
    _pushRules = ref.listenManual(
      ensureCallRingPushRuleUseCaseProvider,
      (_, ensure) => unawaited(ensure.execute()),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _pushRules.close();
    _stopRing();
    super.dispose();
  }

  void _onState(IncomingCallState state) {
    final rings = state is IncomingCallRinging && !state.isInCall;
    if (rings) {
      unawaited(_startRing());
    } else {
      _stopRing();
    }
  }

  Future<void> _startRing() async {
    if (_player != null) return;
    // Not the shared session attributes: a later configure would replace
    // the ringtone ones.
    final player = _player = widget.createPlayer(
      androidApplyAudioAttributes: false,
    );
    try {
      await player.setAndroidAudioAttributes(IncomingCallHost.ringAttributes);
      await player.setLoopMode(LoopMode.one);
      await player.setAsset(IncomingCallHost.ringAsset);
      if (identical(_player, player)) await player.play();
    } on Exception {
      // A ring without sound still shows.
    }
  }

  void _stopRing() {
    final player = _player;
    _player = null;
    unawaited(player?.dispose());
  }

  void _answer() {
    final ring = ref.read(incomingCallControllerProvider.notifier).answer();
    final context = widget.navigatorKey.currentContext;
    if (ring == null || context == null) return;
    unawaited(
      CallScreen.open(
        context,
        roomId: ring.room.id,
        title: ring.roomName ?? ring.room.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(incomingCallControllerProvider, (_, next) => _onState(next));
    final state = ref.watch(incomingCallControllerProvider);
    return Stack(
      children: [
        widget.child,
        if (state case IncomingCallRinging(:final ring))
          Positioned(
            left: 8,
            right: 8,
            top: 0,
            child: SafeArea(
              child: IncomingCallBanner(
                ring: ring,
                onAnswer: _answer,
                onDecline: () => unawaited(
                  ref.read(incomingCallControllerProvider.notifier).decline(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
