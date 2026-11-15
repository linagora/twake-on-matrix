import 'dart:async';

import 'package:twake_chat/data/drive/datasources_impl/drive_file_download_source.provider.dart';
import 'package:twake_chat/data/drive/datasources_impl/drive_intent_source.provider.dart';
import 'package:twake_chat/domain/drive/policy/drive_links_message_policy.provider.dart';
import 'package:twake_chat/pages/drive_picker/providers/drive_picker_platform.provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/drive/entities/drive_download_outcome.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_intent.dart';
import 'package:twake_chat/domain/drive/entities/drive_picker_options.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/drive/policy/drive_links_message_policy.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';
import 'package:twake_chat/domain/drive/sources/drive_file_download_source.dart';
import 'package:twake_chat/domain/drive/sources/drive_intent_source.dart';
import 'package:twake_chat/pages/drive_picker/drive_picker_controller.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_pick_result.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_picker_preparation.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_picker_state.dart';
import '../../providers/fake_active_user_id.dart';
import 'package:twake_chat/providers/drive_session_provider.dart';
import 'package:twake_drive_picker/core.dart';
import 'package:twake_drive_picker/ui.dart' hide DrivePickFailure;

DriveSession _session(String token) => DriveSession(
  idToken: DriveIdToken(value: token, expiresAt: DateTime.utc(2030)),
  platformUrl: Uri.parse('https://alice.twake.example'),
);

const _options = DrivePickerOptions(linkLabel: 'Add as link', darkTheme: false);

Future<int?> _noLimit() async => null;

/// What the fake session does, set per test. A notifier holds no public
/// fields of its own, so the test keeps them here.
class _SessionScript {
  Future<DriveSession> Function() onObtain = () async => _session('first');
  Future<DriveSession> Function() onRenew = () async => _session('renewed');
  int obtains = 0;
  int renewals = 0;
}

class _ScriptedSession extends DriveSessionNotifier {
  _ScriptedSession(this._script);

  final _SessionScript _script;

  @override
  DriveSession? build() => null;

  @override
  Future<DriveSession> obtain() {
    _script.obtains++;
    return _script.onObtain();
  }

  @override
  Future<DriveSession> renew() async {
    _script.renewals++;
    return _script.onRenew();
  }
}

class _FakeIntentSource implements DriveIntentSource {
  final calls = <({DriveSession session, DrivePickerOptions options})>[];
  Future<DriveSession> Function()? lastRenew;

  @override
  Future<DriveIntent> createIntent({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required DrivePickerOptions options,
  }) async {
    calls.add((session: session, options: options));
    lastRenew = renewSession;
    return DriveIntent(
      intentId: 'intent-1',
      intentUrl: Uri.parse('https://drive.example/#/intents/1'),
      client: 'https://chat.example',
    );
  }
}

class _FakeDownloads implements DriveFileDownloadSource {
  Completer<void>? gate;
  int? askedMax;
  List<DrivePickedFile> asked = [];

  @override
  Future<List<DriveDownloadOutcome>> downloadAll(
    List<DrivePickedFile> files, {
    required int? maxBytes,
    void Function(int index, DriveDownloadOutcome outcome)? onOutcome,
  }) async {
    asked = files;
    askedMax = maxBytes;
    await gate?.future;
    final outcomes = <DriveDownloadOutcome>[
      for (final file in files)
        DriveDownloaded(
          DriveDownloadedFile(
            name: file.name,
            path: '/tmp/${file.name}',
            size: 1,
          ),
        ),
    ];
    for (var i = 0; i < outcomes.length; i++) {
      onOutcome?.call(i, outcomes[i]);
    }
    return outcomes;
  }
}

class _FakePlatform extends DrivePickerPlatform {
  const _FakePlatform();

  @override
  bool get isBridgeSupported => false;

  @override
  bool get isBridgeAvailable => false;

  @override
  Future<dynamic> fetchJson({
    required String method,
    required String path,
    Object? body,
    Map<String, String>? headers,
  }) => throw UnsupportedError('no bridge');

  @override
  StopWindowMessageListener listenToWindowMessages(
    WindowMessageCallback onMessage, {
    Object? Function()? expectedFrame,
  }) => () {};

  @override
  Widget buildModal({
    required DriveIntentLoader intentLoader,
    required WorkplaceFilePickerConfigRequest filePickerConfig,
    required DriveIntentImageAssets imageAssets,
    required DriveIconButtonBuilder iconButtonBuilder,
    required WorkplaceLogger logger,
  }) => const SizedBox();
}

DriveDocument _doc(
  String name, {
  String? link,
  String? download,
  String? mime,
}) => DriveDocument(
  id: name,
  name: name,
  size: 1,
  mimeType: mime,
  sharingLink: link == null ? null : Uri.parse(link),
  downloadLink: download == null ? null : Uri.parse(download),
);

const _attachOptions = DrivePickerOptions(
  linkLabel: 'Add as link',
  attachLabel: 'Add as attachment',
  darkTheme: false,
);

enum _PickerPhase { idle, signingIn, open }

enum _PickerOperation { prepare, release, download }

void main() {
  late _SessionScript session;
  late _FakeIntentSource source;
  late _FakeDownloads downloads;
  late ProviderContainer container;

  DrivePickerController controller() =>
      container.read(drivePickerControllerProvider.notifier);

  DrivePickerState state() => container.read(drivePickerControllerProvider);

  int ticket() => switch (state()) {
    DrivePickerSigningIn(:final ticket) => ticket,
    DrivePickerOpen(:final ticket) => ticket,
    DrivePickerIdle() => -1,
  };

  Future<int> openTicket({DrivePickerOptions options = _options}) async =>
      (await controller().prepare(options, maxAttachmentBytes: _noLimit)
              as DrivePickerReady)
          .ticket;

  setUp(() {
    session = _SessionScript();
    source = _FakeIntentSource();
    downloads = _FakeDownloads();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        followFakeActiveUserId(),
        driveSessionProvider.overrideWith(() => _ScriptedSession(session)),
        driveIntentSourceProvider.overrideWithValue(source),
        driveFileDownloadSourceProvider.overrideWithValue(downloads),
        drivePickerPlatformProvider.overrideWithValue(const _FakePlatform()),
        driveLinksMessagePolicyProvider.overrideWithValue(
          const DriveLinksMessagePolicy(requireHttps: true),
        ),
      ],
    );
    container.listen(drivePickerControllerProvider, (_, _) {});
  });

  group('DrivePickerController.prepare', () {
    test('returns what the sheet needs and marks the picker open', () async {
      final result = await controller().prepare(
        _options,
        maxAttachmentBytes: _noLimit,
      );

      expect(result, isA<DrivePickerReady>());
      expect(state(), isA<DrivePickerOpen>());
    });

    test(
      'an unexpected error frees the picker and reaches the caller',
      () async {
        await expectLater(
          controller().prepare(
            _attachOptions,
            maxAttachmentBytes: () async => throw StateError('no config'),
          ),
          throwsStateError,
        );

        expect(state(), isA<DrivePickerIdle>());
        final next = await controller().prepare(
          _options,
          maxAttachmentBytes: _noLimit,
        );
        expect(next, isA<DrivePickerReady>());
      },
    );

    test('a second tap while the picker is open does nothing', () async {
      await controller().prepare(_options, maxAttachmentBytes: _noLimit);

      final second = await controller().prepare(
        _options,
        maxAttachmentBytes: _noLimit,
      );

      expect(second, isA<DrivePickerBusy>());
      expect(session.obtains, 1);
    });

    test('a second tap while signing in does nothing', () async {
      final gate = Completer<DriveSession>();
      session.onObtain = () => gate.future;
      final first = controller().prepare(
        _options,
        maxAttachmentBytes: _noLimit,
      );
      await Future<void>.delayed(Duration.zero);
      expect(state(), isA<DrivePickerSigningIn>());

      final second = await controller().prepare(
        _options,
        maxAttachmentBytes: _noLimit,
      );
      gate.complete(_session('first'));

      expect(second, isA<DrivePickerBusy>());
      expect(await first, isA<DrivePickerReady>());
      expect(session.obtains, 1);
    });

    test('release lets the next pick start', () async {
      final pickTicket = await openTicket();

      controller().release(pickTicket);

      expect(state(), isA<DrivePickerIdle>());
      expect(
        await controller().prepare(_options, maxAttachmentBytes: _noLimit),
        isA<DrivePickerReady>(),
      );
    });

    test('a released sign-in cannot reopen or release a later pick', () async {
      final gate = Completer<DriveSession>();
      session.onObtain = () => gate.future;
      final first = controller().prepare(
        _options,
        maxAttachmentBytes: _noLimit,
      );
      await Future<void>.delayed(Duration.zero);
      controller().release(ticket());

      session.onObtain = () async => _session('second');
      expect(
        await controller().prepare(_options, maxAttachmentBytes: _noLimit),
        isA<DrivePickerReady>(),
      );
      gate.complete(_session('first'));

      expect(await first, isA<DrivePickerCancelled>());
      expect(state(), isA<DrivePickerOpen>());
    });

    test('a cancelled sign-in is silent and frees the picker', () async {
      session.onObtain = () async => throw const DriveSignInCancelled();

      final result = await controller().prepare(
        _options,
        maxAttachmentBytes: _noLimit,
      );

      expect(result, isA<DrivePickerCancelled>());
      expect(state(), isA<DrivePickerIdle>());
    });

    test('a switch of account during the sign-in is silent', () async {
      session.onObtain = () async => throw const DriveSessionSuperseded();

      expect(
        await controller().prepare(_options, maxAttachmentBytes: _noLimit),
        isA<DrivePickerCancelled>(),
      );
      expect(state(), isA<DrivePickerIdle>());
    });

    test('a switch while reading the upload limit cancels the pick', () async {
      final limit = Completer<int?>();
      final pending = controller().prepare(
        _attachOptions,
        maxAttachmentBytes: () => limit.future,
      );
      await Future<void>.delayed(Duration.zero);
      expect(state(), isA<DrivePickerSigningIn>());

      container
          .read(fakeActiveUserIdProvider.notifier)
          .switchTo('@bob:example.org');
      await Future<void>.delayed(Duration.zero);
      limit.complete(5000);

      expect(await pending, isA<DrivePickerCancelled>());
      expect(state(), isA<DrivePickerIdle>());
    });

    test('a switch closes an open picker before another pick', () async {
      await controller().prepare(_options, maxAttachmentBytes: _noLimit);
      expect(state(), isA<DrivePickerOpen>());

      container
          .read(fakeActiveUserIdProvider.notifier)
          .switchTo('@bob:example.org');
      await Future<void>.delayed(Duration.zero);

      expect(state(), isA<DrivePickerIdle>());
      expect(
        await controller().prepare(_options, maxAttachmentBytes: _noLimit),
        isA<DrivePickerReady>(),
      );
    });

    final problems = <String, (DriveException, DrivePickerProblem)>{
      'sign-in failed': (
        const DriveSignInFailed(DriveSignInFailure.tokenEndpoint),
        DrivePickerProblem.signInFailed,
      ),
      'workplace unknown': (
        const DriveWorkplaceUnknown(),
        DrivePickerProblem.signInFailed,
      ),
      'not configured': (
        const DriveNotConfigured(),
        DrivePickerProblem.couldNotOpen,
      ),
      'chat app missing': (
        const DriveChatAppMissing(),
        DrivePickerProblem.chatAppMissing,
      ),
      'exchange rejected': (
        const DriveExchangeRejected(),
        DrivePickerProblem.couldNotOpen,
      ),
      'intent failed': (
        const DriveIntentFailed(),
        DrivePickerProblem.couldNotOpen,
      ),
      'rate limited': (
        const DriveRateLimited(),
        DrivePickerProblem.couldNotOpen,
      ),
      'timed out': (const DriveTimedOut(), DrivePickerProblem.couldNotOpen),
      'offline': (const DriveOffline(), DrivePickerProblem.couldNotOpen),
    };
    for (final entry in problems.entries) {
      test(
        '${entry.key} is reported as ${entry.value.$2.name} and frees the picker',
        () async {
          session.onObtain = () async => throw entry.value.$1;

          final result = await controller().prepare(
            _options,
            maxAttachmentBytes: _noLimit,
          );

          expect(
            result,
            isA<DrivePickerUnavailable>().having(
              (r) => r.problem,
              'problem',
              entry.value.$2,
            ),
          );
          expect(state(), isA<DrivePickerIdle>());
          // The next try works on a clean controller.
          session.onObtain = () async => _session('again');
          expect(
            await controller().prepare(_options, maxAttachmentBytes: _noLimit),
            isA<DrivePickerReady>(),
          );
        },
      );
    }

    test('a sign-in that ends after the container is gone is silent', () async {
      final gate = Completer<DriveSession>();
      session.onObtain = () => gate.future;
      final pending = controller().prepare(
        _options,
        maxAttachmentBytes: _noLimit,
      );
      await Future<void>.delayed(Duration.zero);

      container.dispose();
      gate.complete(_session('late'));

      expect(await pending, isA<DrivePickerCancelled>());
    });

    test('release after the container is gone does not throw', () async {
      final notifier = controller();
      final pickTicket = await openTicket();

      container.dispose();

      expect(() => notifier.release(pickTicket), returnsNormally);
    });
  });

  group('DrivePickerController state transitions', () {
    for (final phase in _PickerPhase.values) {
      for (final operation in _PickerOperation.values) {
        test('${phase.name} x ${operation.name}', () async {
          Completer<DriveSession>? signInGate;
          Future<DrivePickerPreparation>? pendingPrepare;
          switch (phase) {
            case _PickerPhase.idle:
              break;
            case _PickerPhase.signingIn:
              signInGate = Completer<DriveSession>();
              session.onObtain = () => signInGate!.future;
              pendingPrepare = controller().prepare(
                _options,
                maxAttachmentBytes: _noLimit,
              );
              await Future<void>.delayed(Duration.zero);
              break;
            case _PickerPhase.open:
              await controller().prepare(
                _options,
                maxAttachmentBytes: _noLimit,
              );
              break;
          }

          switch (operation) {
            case _PickerOperation.prepare:
              final result = await controller().prepare(
                _options,
                maxAttachmentBytes: _noLimit,
              );
              expect(
                result,
                phase == _PickerPhase.idle
                    ? isA<DrivePickerReady>()
                    : isA<DrivePickerBusy>(),
              );
              break;
            case _PickerOperation.release:
              controller().release(ticket());
              break;
            case _PickerOperation.download:
              if (phase == _PickerPhase.open) {
                expect(
                  await controller().download(
                    [],
                    ticket: ticket(),
                    onOutcome: (_, _) {},
                  ),
                  isEmpty,
                );
              } else {
                // A picker nobody owns answers for the ticket first.
                expect(
                  () => controller().download(
                    [],
                    ticket: ticket(),
                    onOutcome: (_, _) {},
                  ),
                  phase == _PickerPhase.idle
                      ? throwsA(isA<DriveSessionSuperseded>())
                      : throwsStateError,
                );
              }
              break;
          }

          final expectedPhase = switch (operation) {
            _PickerOperation.prepare when phase == _PickerPhase.idle =>
              DrivePickerOpen,
            _PickerOperation.release => DrivePickerIdle,
            _PickerOperation.download when phase == _PickerPhase.open =>
              DrivePickerIdle,
            _ => switch (phase) {
              _PickerPhase.idle => DrivePickerIdle,
              _PickerPhase.signingIn => DrivePickerSigningIn,
              _PickerPhase.open => DrivePickerOpen,
            },
          };
          expect(state().runtimeType, expectedPhase);

          if (signInGate != null) {
            signInGate.complete(_session('late'));
            expect(
              await pendingPrepare,
              operation == _PickerOperation.release
                  ? isA<DrivePickerCancelled>()
                  : isA<DrivePickerReady>(),
            );
          }
        });
      }
    }
  });

  group('DrivePickerController request', () {
    test(
      'the loader creates the intent for the session it signed in',
      () async {
        final ready =
            await controller().prepare(_options, maxAttachmentBytes: _noLimit)
                as DrivePickerReady;

        final intent = await ready.request.intentLoader();

        expect(source.calls.single.session.idToken.value, 'first');
        expect(source.calls.single.options, _options);
        expect(intent.intentId, 'intent-1');
        expect(
          intent.intentUrl,
          Uri.parse('https://drive.example/#/intents/1'),
        );
        expect(intent.client, 'https://chat.example');
      },
    );

    test('a stale token is renewed through the session owner', () async {
      final ready =
          await controller().prepare(_options, maxAttachmentBytes: _noLimit)
              as DrivePickerReady;
      await ready.request.intentLoader();

      final renewed = await source.lastRenew!();

      expect(renewed.idToken.value, 'renewed');
      expect(session.renewals, 1);
    });

    test('a previous account cannot load an intent after a switch', () async {
      final ready =
          await controller().prepare(_options, maxAttachmentBytes: _noLimit)
              as DrivePickerReady;
      container
          .read(fakeActiveUserIdProvider.notifier)
          .switchTo('@bob:example.org');
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        ready.request.intentLoader(),
        throwsA(isA<DriveSessionSuperseded>()),
      );
      expect(source.calls, isEmpty);
    });

    test('a switched account cannot renew an old pick', () async {
      final ready =
          await controller().prepare(_options, maxAttachmentBytes: _noLimit)
              as DrivePickerReady;
      await ready.request.intentLoader();
      final renewalGate = Completer<DriveSession>();
      session.onRenew = () => renewalGate.future;
      final renewal = source.lastRenew!();
      await Future<void>.delayed(Duration.zero);

      container
          .read(fakeActiveUserIdProvider.notifier)
          .switchTo('@bob:example.org');
      await Future<void>.delayed(Duration.zero);
      renewalGate.complete(_session('bob-token'));

      await expectLater(renewal, throwsA(isA<DriveSessionSuperseded>()));
      expect(session.renewals, 1);
    });

    test('asks for the link button only, and no attach button', () async {
      final ready =
          await controller().prepare(_options, maxAttachmentBytes: _noLimit)
              as DrivePickerReady;

      final config = ready.request.filePickerConfig;

      expect(config.sharingLink.label, 'Add as link');
      expect(config.downloadLink, isNull);
    });

    test('follows the dark theme', () async {
      final ready =
          await controller().prepare(
                const DrivePickerOptions(linkLabel: 'x', darkTheme: true),
                maxAttachmentBytes: _noLimit,
              )
              as DrivePickerReady;

      expect(ready.request.filePickerConfig.theme.toJson()['type'], 'dark');
    });
  });

  group('DrivePickerController.resultOf', () {
    test('picked links become one message, a line each', () async {
      final pickTicket = await openTicket();
      final result = controller().resultOf(
        DrivePickOutcomePicked([
          _doc('a.pdf', link: 'https://x.example/s/1'),
          _doc('b.pdf', link: 'https://x.example/s/2'),
        ]),
        ticket: pickTicket,
      );

      expect(
        result,
        isA<DrivePickLinks>().having((r) => r.texts, 'texts', [
          '[a.pdf](https://x.example/s/1)\n[b.pdf](https://x.example/s/2)',
        ]),
      );
    });

    test('a pick with no link that can be sent is a failure', () async {
      final pickTicket = await openTicket();
      final result = controller().resultOf(
        DrivePickOutcomePicked([
          _doc('a.pdf'),
          _doc('b.pdf', link: 'http://x.example/s'),
        ]),
        ticket: pickTicket,
      );

      expect(result, isA<DrivePickFailed>());
    });

    test('a cancel sends nothing', () async {
      final pickTicket = await openTicket();
      expect(
        controller().resultOf(
          const DrivePickOutcomeCancelled(),
          ticket: pickTicket,
        ),
        isA<DrivePickNothing>(),
      );
    });

    for (final cause in <Object>[
      const DriveSignInCancelled(),
      const DriveSessionSuperseded(),
    ]) {
      test('a pick that ends in ${cause.toString()} sends nothing', () async {
        final pickTicket = await openTicket();

        expect(
          controller().resultOf(
            DrivePickOutcomeFailed(cause),
            ticket: pickTicket,
          ),
          isA<DrivePickNothing>(),
        );
      });
    }

    final failureCauses = <String, (Object, DrivePickFailure)>{
      'the page never said ready': (
        DriveIntentTimeoutException(),
        DrivePickFailure.pickerTimedOut,
      ),
      'the page did not load': (
        DriveIntentPageLoadException('x'),
        DrivePickFailure.pickerPageFailed,
      ),
      'the page reported an error': (
        DriveIntentErrorException(),
        DrivePickFailure.pickerReportedError,
      ),
      'no document was valid': (
        DriveIntentNoValidDocumentException(),
        DrivePickFailure.pickerNoValidDocument,
      ),
      'the intent request timed out': (
        const DriveTimedOut(),
        DrivePickFailure.intentUnreachable,
      ),
      'the intent request was refused': (
        const DriveIntentFailed(),
        DrivePickFailure.intentFailed,
      ),
      'something else': (StateError('x'), DrivePickFailure.pickerFailed),
    };
    failureCauses.forEach((cause, expected) {
      test('a failed pick names why: $cause', () async {
        final pickTicket = await openTicket();
        final result = controller().resultOf(
          DrivePickOutcomeFailed(expected.$1),
          ticket: pickTicket,
        );
        expect(result, isA<DrivePickFailed>());
        expect((result as DrivePickFailed).reason, expected.$2);
      });
    });

    test(
      'an old account result and release cannot affect a new pick',
      () async {
        final oldTicket = await openTicket();
        container
            .read(fakeActiveUserIdProvider.notifier)
            .switchTo('@bob:example.org');
        await Future<void>.delayed(Duration.zero);
        final newTicket = await openTicket();
        final outcome = DrivePickOutcomePicked([
          _doc('a.pdf', link: 'https://x.example/s/1'),
        ]);

        expect(
          controller().resultOf(outcome, ticket: oldTicket),
          isA<DrivePickNothing>(),
        );
        expect(
          () => controller().download(
            [],
            ticket: oldTicket,
            onOutcome: (_, _) {},
          ),
          throwsA(isA<DriveSessionSuperseded>()),
        );
        controller().release(oldTicket);
        expect(state(), isA<DrivePickerOpen>());
        expect(
          controller().resultOf(outcome, ticket: newTicket),
          isA<DrivePickLinks>(),
        );
      },
    );
  });

  group('DrivePickerController attach', () {
    test(
      'asks the upload limit only when the attach button is offered',
      () async {
        var asked = 0;
        Future<int?> limit() async {
          asked++;
          return 5000;
        }

        final pickTicket =
            (await controller().prepare(_options, maxAttachmentBytes: limit)
                    as DrivePickerReady)
                .ticket;
        expect(asked, 0);
        controller().release(pickTicket);
        await controller().prepare(_attachOptions, maxAttachmentBytes: limit);

        expect(asked, 1);
      },
    );

    test(
      'offers the attach button with the upload limit and no folders',
      () async {
        final ready =
            await controller().prepare(
                  _attachOptions,
                  maxAttachmentBytes: () async => 5000,
                )
                as DrivePickerReady;

        final attach = ready.request.filePickerConfig.downloadLink!;

        expect(attach.label, 'Add as attachment');
        expect(attach.maxFileSize, 5000);
        expect(attach.allowFolder, isFalse);
      },
    );

    test('the intent is created with the same options as the sheet', () async {
      final ready =
          await controller().prepare(
                _attachOptions,
                maxAttachmentBytes: () async => 5000,
              )
              as DrivePickerReady;

      await ready.request.intentLoader();

      expect(source.calls.single.options.attachLabel, 'Add as attachment');
      expect(source.calls.single.options.maxAttachmentBytes, 5000);
    });

    test('picked files with download links are an attach result', () async {
      final pickTicket = await openTicket();
      final result = controller().resultOf(
        DrivePickOutcomePicked([
          _doc('a.pdf', download: 'https://x.example/d/1'),
          _doc('b.png', download: 'https://x.example/d/2'),
        ]),
        ticket: pickTicket,
      );

      expect(
        result,
        isA<DrivePickAttach>()
            .having((r) => r.files.map((f) => f.name), 'files', [
              'a.pdf',
              'b.png',
            ])
            .having((r) => r.skippedShortcuts, 'skipped', 0),
      );
    });

    test('a shortcut among the files is counted and not attached', () async {
      final pickTicket = await openTicket();
      final result = controller().resultOf(
        DrivePickOutcomePicked([
          _doc('a.pdf', download: 'https://x.example/d/1'),
          _doc('go.url', download: 'https://x.example/d/2'),
        ]),
        ticket: pickTicket,
      );

      expect(
        result,
        isA<DrivePickAttach>()
            .having((r) => r.files, 'files', hasLength(1))
            .having((r) => r.skippedShortcuts, 'skipped', 1),
      );
    });

    test('only shortcuts leaves nothing to attach', () async {
      final pickTicket = await openTicket();
      final result = controller().resultOf(
        DrivePickOutcomePicked([
          _doc(
            'go',
            download: 'https://x.example/d/2',
            mime: 'application/internet-shortcut',
          ),
        ]),
        ticket: pickTicket,
      );

      expect(result, isA<DrivePickShortcutsOnly>());
    });

    test('sharing links win over download links', () async {
      final pickTicket = await openTicket();
      final result = controller().resultOf(
        DrivePickOutcomePicked([
          _doc(
            'a',
            link: 'https://x.example/s/1',
            download: 'https://x.example/d/1',
          ),
        ]),
        ticket: pickTicket,
      );

      expect(result, isA<DrivePickLinks>());
    });

    test('download uses the limit it read and reports each file', () async {
      final pickTicket =
          (await controller().prepare(
                    _attachOptions,
                    maxAttachmentBytes: () async => 5000,
                  )
                  as DrivePickerReady)
              .ticket;
      final file = DrivePickedFile(
        id: 'a',
        name: 'a.pdf',
        size: 1,
        downloadUri: Uri.parse('https://x.example/d/1'),
      );
      final heard = <int>[];

      final outcomes = await controller().download(
        [file],
        ticket: pickTicket,
        onOutcome: (index, outcome) => heard.add(index),
      );

      expect(outcomes.single, isA<DriveDownloaded>());
      expect(heard, [0]);
      expect(downloads.askedMax, 5000);
    });

    test(
      'files handed over free the picker while they are on their way',
      () async {
        final pickTicket = await openTicket(options: _attachOptions);
        downloads.gate = Completer<void>();
        final file = DrivePickedFile(
          id: 'a',
          name: 'a.pdf',
          size: 1,
          downloadUri: Uri.parse('https://x.example/d/1'),
        );

        final pending = controller().download(
          [file],
          ticket: pickTicket,
          onOutcome: (index, outcome) {},
        );

        expect(state(), isA<DrivePickerIdle>());
        expect(
          await controller().prepare(_options, maxAttachmentBytes: _noLimit),
          isA<DrivePickerReady>(),
        );
        downloads.gate!.complete();
        await pending;
      },
    );

    test('files handed over per file survive an account switch', () async {
      final pickTicket = await openTicket(options: _attachOptions);
      downloads.gate = Completer<void>();
      final file = DrivePickedFile(
        id: 'a',
        name: 'a.pdf',
        size: 1,
        downloadUri: Uri.parse('https://x.example/d/1'),
      );
      final heard = <String>[];
      final pending = controller().download(
        [file],
        ticket: pickTicket,
        onOutcome: (index, outcome) {
          if (outcome is DriveDownloaded) heard.add(outcome.file.name);
        },
      );
      await Future<void>.delayed(Duration.zero);
      container
          .read(fakeActiveUserIdProvider.notifier)
          .switchTo('@bob:example.org');
      await Future<void>.delayed(Duration.zero);
      final newTicket = await openTicket();
      downloads.gate!.complete();

      // The caller owns the file now: no error, and nothing deleted.
      expect(await pending, hasLength(1));
      expect(heard, ['a.pdf']);
      expect(state(), isA<DrivePickerOpen>());
      controller().release(newTicket);
    });
  });
}
