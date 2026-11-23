import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:record/record.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/pages/chat/chat_input_row_send_btn.dart';
import 'package:twake_chat/presentation/mixins/audio_mixin.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

/// Desktop voice messages (PR #3725, nqhhdev and jbrnzl reviews): the WAV
/// written to temp must never outlive the composer, and the 30-minute
/// auto-stop must not lose the recording.
///
/// These tests only make sense on a desktop host (macOS, Linux, Windows),
/// which is where `flutter test` runs.

class _Composer with AudioMixin {}

/// The `record` plugin seen from Dart. `start` writes the WAV like the native
/// recorder does, and every state change is reported on [onStateChanged] as
/// the native side does (so the auto-stop is followed by `RecordState.stop`).
class _FakeRecordPlatform extends RecordPlatform {
  final _states = StreamController<RecordState>.broadcast();
  final wavBytes = Uint8List.fromList(List.generate(64, (i) => i));

  String? path;
  bool recording = false;

  @override
  Future<void> create(String recorderId) async {}

  @override
  Future<void> start(
    String recorderId,
    RecordConfig config, {
    required String path,
  }) async {
    File(path).writeAsBytesSync(wavBytes);
    this.path = path;
    recording = true;
    _states.add(RecordState.record);
  }

  @override
  Future<String?> stop(String recorderId) async {
    if (!recording) return null;
    recording = false;
    _states.add(RecordState.stop);
    return path;
  }

  @override
  Future<void> cancel(String recorderId) async {
    recording = false;
    final current = path;
    if (current != null && File(current).existsSync()) {
      File(current).deleteSync();
    }
  }

  @override
  Future<void> dispose(String recorderId) async {
    recording = false;
  }

  @override
  Future<bool> isRecording(String recorderId) async => recording;

  @override
  Future<bool> isPaused(String recorderId) async => false;

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) async =>
      true;

  @override
  Future<bool> isEncoderSupported(
    String recorderId,
    AudioEncoder encoder,
  ) async => true;

  @override
  Future<Amplitude> getAmplitude(String recorderId) async =>
      Amplitude(current: -20, max: 0);

  @override
  Future<List<InputDevice>> listInputDevices(String recorderId) async => [];

  @override
  Future<void> pause(String recorderId) async {}

  @override
  Future<void> resume(String recorderId) async {}

  @override
  Future<Stream<Uint8List>> startStream(
    String recorderId,
    RecordConfig config,
  ) => throw UnimplementedError();

  @override
  Stream<RecordState> onStateChanged(String recorderId) => _states.stream;
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

const _thirtyMinutes = Duration(seconds: AudioMixin.maxRecordDurationInSeconds);

/// What the chat's Send does (`Chat.sendVoiceMessageWeb`,
/// `DraftChat.sendVoiceMessageWeb`): read the duration, stop the recorder for
/// its file, then wrap the file as the voice message.
Future<TwakeAudioFile?> _send(_Composer composer) async {
  final duration = Duration(seconds: composer.recordDurationWebNotifier.value);
  final path = await composer.stopRecordWeb();
  if (path == null) return null;
  return composer.createMatrixAudioFileFromPath(path: path, duration: duration);
}

/// File deletion and reading are real I/O, which fake time does not run.
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

Finder _iconButton(String imagePath) => find.byWidgetPredicate(
  (widget) => widget is TwakeIconButton && widget.imagePath == imagePath,
);

void main() {
  late Directory temp;
  late _FakeRecordPlatform recorder;
  late RecordPlatform originalRecorder;
  late PathProviderPlatform originalPathProvider;
  late _Composer composer;
  late BuildContext context;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('voice_message_test_');
    recorder = _FakeRecordPlatform();
    originalRecorder = RecordPlatform.instance;
    RecordPlatform.instance = recorder;
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    composer = _Composer();
  });

  tearDown(() {
    RecordPlatform.instance = originalRecorder;
    PathProviderPlatform.instance = originalPathProvider;
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  Future<void> pumpChat(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );

  /// Starts a desktop recording and returns the WAV it writes.
  Future<File> startRecording(WidgetTester tester) async {
    await pumpChat(tester);
    await composer.onTapRecorderWeb(context: context);
    await tester.pump();
    final wav = File(recorder.path!);
    expect(wav.existsSync(), isTrue, reason: 'the recorder wrote its WAV');
    return wav;
  }

  Future<void> reachAutoStop(WidgetTester tester) async {
    await tester.pump(_thirtyMinutes);
    await tester.pump();
    expect(
      recorder.recording,
      isFalse,
      reason: 'the recorder stops by itself after 30 minutes',
    );
  }

  group('closing the chat', () {
    testWidgets('mid-recording stops the recorder and deletes the WAV', (
      tester,
    ) async {
      final wav = await startRecording(tester);

      composer.disposeAudioMixin();
      await _settleIo(tester);

      expect(recorder.recording, isFalse);
      expect(wav.existsSync(), isFalse);
    });

    testWidgets('after the auto-stop, without sending, deletes the WAV', (
      tester,
    ) async {
      final wav = await startRecording(tester);
      await reachAutoStop(tester);

      composer.disposeAudioMixin();
      await _settleIo(tester);

      expect(wav.existsSync(), isFalse);
    });

    testWidgets('after the message was sent does not fail', (tester) async {
      await startRecording(tester);
      final sending = _send(composer);
      await _settleIo(tester);
      expect(await sending, isNotNull);

      composer.disposeAudioMixin();
      await _settleIo(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('that never recorded does nothing', (tester) async {
      await pumpChat(tester);

      composer.disposeAudioMixin();
      await _settleIo(tester);

      expect(tester.takeException(), isNull);
      expect(temp.listSync(), isEmpty);
    });
  });

  group('the 30-minute auto-stop', () {
    testWidgets('keeps Send and Delete on screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ChatInputRowSendBtn(
                inputText: ValueNotifier(''),
                onTap: () {},
                audioRecordStateNotifier: composer.audioRecordStateNotifier,
                onTapRecorderWeb: () => composer.onTapRecorderWeb(context: ctx),
                onFinishRecorderWeb: () {},
                onDeleteRecorderWeb: () {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(_iconButton(Assets.images.icRecorder.path));
      await tester.pump();
      await tester.pump();
      expect(_iconButton(Assets.images.icSend.path), findsOneWidget);

      await reachAutoStop(tester);

      expect(_iconButton(Assets.images.icSend.path), findsOneWidget);
      expect(
        _iconButton(Assets.images.icDeleteRecorderWeb.path),
        findsOneWidget,
      );

      composer.disposeAudioMixin();
      await _settleIo(tester);
    });

    testWidgets('then Send sends the recorded file and removes it from temp', (
      tester,
    ) async {
      final wav = await startRecording(tester);
      await reachAutoStop(tester);

      final sending = _send(composer);
      await _settleIo(tester);
      final sent = await sending;

      expect(sent, isNotNull, reason: 'Send after the auto-stop must not fail');
      expect(sent!.bytes, recorder.wavBytes);
      expect(wav.existsSync(), isFalse);

      composer.disposeAudioMixin();
      await _settleIo(tester);
    });

    testWidgets('then Send sends a 30-minute voice message', (tester) async {
      await startRecording(tester);
      await reachAutoStop(tester);

      final sending = _send(composer);
      await _settleIo(tester);
      final sent = await sending;

      expect(sent?.duration, _thirtyMinutes.inMilliseconds);

      composer.disposeAudioMixin();
      await _settleIo(tester);
    });

    testWidgets('then Delete deletes the WAV', (tester) async {
      final wav = await startRecording(tester);
      await reachAutoStop(tester);

      final discarding = composer.discardRecordWeb();
      await _settleIo(tester);
      await discarding;

      expect(wav.existsSync(), isFalse);

      composer.disposeAudioMixin();
      await _settleIo(tester);
    });
  });

  group('during the recording', () {
    testWidgets('Send sends the recorded file and removes it from temp', (
      tester,
    ) async {
      final wav = await startRecording(tester);
      await tester.pump(const Duration(seconds: 5));

      final sending = _send(composer);
      await _settleIo(tester);
      final sent = await sending;

      expect(sent?.bytes, recorder.wavBytes);
      expect(sent?.duration, const Duration(seconds: 5).inMilliseconds);
      expect(wav.existsSync(), isFalse);

      composer.disposeAudioMixin();
      await _settleIo(tester);
    });

    testWidgets('Delete stops the recorder and deletes the WAV', (
      tester,
    ) async {
      final wav = await startRecording(tester);

      final discarding = composer.discardRecordWeb();
      await _settleIo(tester);
      await discarding;

      expect(recorder.recording, isFalse);
      expect(wav.existsSync(), isFalse);

      composer.disposeAudioMixin();
      await _settleIo(tester);
    });
  });
}
