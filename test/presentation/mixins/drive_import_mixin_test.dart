import 'dart:async';
import 'dart:io';

import 'package:twake_chat/data/drive/datasources_impl/drive_file_download_source.provider.dart';
import 'package:twake_chat/data/drive/datasources_impl/drive_intent_source.provider.dart';
import 'package:twake_chat/domain/drive/policy/drive_links_message_policy.provider.dart';
import 'package:twake_chat/pages/drive_picker/providers/drive_picker_platform.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
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
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/drive_picker/drive_picker_controller.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_picker_preparation.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_pending_file.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart' show ProgressDialog;
import 'package:twake_chat/pages/drive_picker/states/drive_picker_state.dart';
import 'package:twake_chat/pages/drive_picker/widgets/drive_picker_page.dart';
import 'package:twake_chat/presentation/mixins/drive_import_mixin.dart';
import '../../providers/fake_active_user_id.dart';
import 'package:twake_chat/providers/drive_session_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_drive_picker/core.dart';
import 'package:twake_drive_picker/ui.dart';

class _TestMixin with DriveImportMixin {}

/// What the fake session does, set per test. A notifier holds no public
/// fields of its own, so the test keeps them here.
class _SessionScript {
  Future<DriveSession> Function() onObtain = () async => DriveSession(
    idToken: DriveIdToken(value: 'token', expiresAt: DateTime.utc(2030)),
    platformUrl: Uri.parse('https://alice.twake.example'),
  );
  int obtains = 0;
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
}

class _FakeIntentSource implements DriveIntentSource {
  @override
  Future<DriveIntent> createIntent({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required DrivePickerOptions options,
  }) async => DriveIntent(
    intentId: 'intent',
    intentUrl: Uri.parse('https://drive.example/#/intents/1'),
  );
}

class _FakeDownloads implements DriveFileDownloadSource {
  Completer<void>? gate;
  Object? error;
  final failing = <String>{};
  int? askedMax;

  @override
  Future<List<DriveDownloadOutcome>> downloadAll(
    List<DrivePickedFile> files, {
    required int? maxBytes,
    void Function(int index, DriveDownloadOutcome outcome)? onOutcome,
  }) async {
    askedMax = maxBytes;
    await gate?.future;
    if (error != null) throw error!;
    final outcomes = <DriveDownloadOutcome>[
      for (final file in files)
        failing.contains(file.name)
            ? DriveDownloadRejected(file, DriveDownloadFailure.failed)
            : DriveDownloaded(
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

DriveDocument _attachDoc(String name, {String? mime}) => DriveDocument(
  id: name,
  name: name,
  size: 1,
  mimeType: mime,
  downloadLink: Uri.parse('https://x.example/d/$name'),
);

/// Stands in for the WebView: buttons play what the Drive page reports.
class _ViewPlatform extends DrivePickerPlatform {
  const _ViewPlatform();

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

  @override
  Widget buildView({
    required DriveIntentLoader intentLoader,
    required WorkplaceFilePickerConfigRequest filePickerConfig,
    required DriveIntentImageAssets? imageAssets,
    required DriveIconButtonBuilder iconButtonBuilder,
    required WorkplaceLogger logger,
    ValueChanged<DrivePickOutcome>? onResult,
    VoidCallback? onClose,
  }) => Column(
    key: const Key('drive-view'),
    children: [
      TextButton(
        key: const Key('pick'),
        onPressed: () {
          onResult?.call(
            DrivePickOutcomePicked([
              DriveDocument(
                id: 'a',
                name: _firstPickedName,
                size: 1,
                sharingLink: Uri.parse('https://x.example/s/1'),
              ),
              DriveDocument(
                id: 'b',
                name: 'b.pdf',
                size: 1,
                sharingLink: Uri.parse('https://x.example/s/2'),
              ),
            ]),
          );
          // The view asks twice in a row: the page must pop once.
          onClose?.call();
          onClose?.call();
        },
        child: const Text('pick'),
      ),
      TextButton(
        key: const Key('attach'),
        onPressed: () {
          onResult?.call(
            DrivePickOutcomePicked([_attachDoc('a.pdf'), _attachDoc('b.pdf')]),
          );
          onClose?.call();
        },
        child: const Text('attach'),
      ),
      TextButton(
        key: const Key('attach-mixed'),
        onPressed: () {
          onResult?.call(
            DrivePickOutcomePicked([_attachDoc('a.pdf'), _attachDoc('go.url')]),
          );
          onClose?.call();
        },
        child: const Text('attach-mixed'),
      ),
      TextButton(
        key: const Key('attach-shortcuts'),
        onPressed: () {
          onResult?.call(DrivePickOutcomePicked([_attachDoc('go.url')]));
          onClose?.call();
        },
        child: const Text('attach-shortcuts'),
      ),
      TextButton(
        key: const Key('attach-bad'),
        onPressed: () {
          onResult?.call(
            DrivePickOutcomePicked([_attachDoc('x.pdf'), _attachDoc('y.pdf')]),
          );
          onClose?.call();
        },
        child: const Text('attach-bad'),
      ),
      TextButton(
        key: const Key('cancel'),
        onPressed: () {
          onResult?.call(const DrivePickOutcomeCancelled());
          onClose?.call();
        },
        child: const Text('cancel'),
      ),
      TextButton(
        key: const Key('fail'),
        onPressed: () {
          onResult?.call(DrivePickOutcomeFailed(StateError('x')));
          onClose?.call();
        },
        child: const Text('fail'),
      ),
    ],
  );
}

class _ThrowingLinksPolicy extends DriveLinksMessagePolicy {
  _ThrowingLinksPolicy() : super(requireHttps: true);

  @override
  String format(List<DrivePickedFile> files) =>
      throw Exception('the links cannot be formatted');
}

class _Host extends ConsumerWidget {
  const _Host({required this.mixin, required this.actions});

  final _TestMixin mixin;
  final DriveImportActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: ElevatedButton(
        key: const Key('open'),
        onPressed: () =>
            mixin.addFromTwakeDrive(context, ref: ref, actions: actions),
        child: const Text('open'),
      ),
    ),
  );
}

/// The name of the first file the fake Drive view picks.
String _firstPickedName = 'a.pdf';

void main() {
  late _SessionScript session;
  late List<String> sent;
  late Object? sendError;
  late int linksSent;
  late _FakeDownloads downloads;
  late List<List<DrivePendingFile>> filesSent;
  Object? filesError;
  late int? limit;
  late List<String> failures;
  late bool signingInShown;
  late int signInRuns;
  DriveLinksMessagePolicy? linksPolicy;
  VoidCallback? afterLinkMessage;

  Future<void> pumpHost(WidgetTester tester, {ThemeData? theme}) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          followFakeActiveUserId(),
          driveSessionProvider.overrideWith(() => _ScriptedSession(session)),
          driveIntentSourceProvider.overrideWithValue(_FakeIntentSource()),
          driveFileDownloadSourceProvider.overrideWithValue(downloads),
          drivePickerPlatformProvider.overrideWithValue(const _ViewPlatform()),
          driveLinksMessagePolicyProvider.overrideWithValue(
            linksPolicy ?? const DriveLinksMessagePolicy(requireHttps: true),
          ),
        ],
        child: MaterialApp(
          theme: theme,
          localizationsDelegates: const [
            L10n.delegate,
            ...DrivePickerLocalizations.localizationsDelegates,
          ],
          supportedLocales: L10n.supportedLocales,
          home: _Host(
            mixin: _TestMixin(),
            actions: DriveImportActions(
              sendLinks: (text) async {
                if (sendError != null) throw sendError!;
                sent.add(text);
                afterLinkMessage?.call();
              },
              onLinksSent: () => linksSent++,
              maxAttachmentBytes: () async => limit,
              onFailure: (step, error, stackTrace) => failures.add(step),
              whileSigningIn: (task) async {
                signInRuns++;
                signingInShown = true;
                try {
                  return await task();
                } finally {
                  signingInShown = false;
                }
              },
              sendFiles: (files) async {
                if (filesError != null) throw filesError!;
                filesSent.add(files);
              },
            ),
          ),
        ),
      ),
    );
  }

  DrivePickerState pickerState(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byKey(const Key('open'))),
      ).read(drivePickerControllerProvider);

  ProviderContainer providerContainer(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byKey(const Key('open'), skipOffstage: false)),
      );

  Future<void> switchAccount(WidgetTester tester) async {
    providerContainer(
      tester,
    ).read(fakeActiveUserIdProvider.notifier).switchTo('@bob:example.org');
    await tester.pump();
  }

  Future<int> startNewPick(WidgetTester tester) async {
    final ready =
        await providerContainer(tester)
                .read(drivePickerControllerProvider.notifier)
                .prepare(
                  const DrivePickerOptions(
                    linkLabel: 'Add as link',
                    attachLabel: 'Add as attachment',
                    darkTheme: false,
                  ),
                  maxAttachmentBytes: () async => 5000,
                )
            as DrivePickerReady;
    await tester.pump();
    return ready.ticket;
  }

  setUp(() {
    session = _SessionScript();
    sent = [];
    sendError = null;
    linksSent = 0;
    downloads = _FakeDownloads();
    filesSent = [];
    filesError = null;
    limit = 5000;
    failures = [];
    signingInShown = false;
    signInRuns = 0;
    linksPolicy = null;
    afterLinkMessage = null;
    _firstPickedName = 'a.pdf';
    getIt.registerSingleton<ResponsiveUtils>(ResponsiveUtils());
  });

  tearDown(() async => getIt.reset());

  group('DriveImportMixin.addFromTwakeDrive', () {
    testWidgets(
      'sends the picked links as one message through the closure it was given',
      (tester) async {
        await pumpHost(tester);

        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('pick')));
        await tester.pumpAndSettle();

        expect(sent, [
          '[a.pdf](https://x.example/s/1)\n[b.pdf](https://x.example/s/2)',
        ]);
        expect(linksSent, 1);
        // The page is gone, popped once: the host page is still there.
        expect(find.byKey(const Key('drive-view')), findsNothing);
        expect(find.byKey(const Key('open')), findsOneWidget);
        expect(pickerState(tester), isA<DrivePickerIdle>());
      },
    );

    testWidgets('a long pick is sent as several messages, each cut between '
        'links', (tester) async {
      _firstPickedName = 'n' * 3990;
      await pumpHost(tester);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick')));
      await tester.pumpAndSettle();

      expect(sent, hasLength(2));
      expect(sent.last, '[b.pdf](https://x.example/s/2)');
      expect(linksSent, 1);
    });

    testWidgets('an account switch between two messages stops the rest', (
      tester,
    ) async {
      _firstPickedName = 'n' * 3990;
      await pumpHost(tester);
      afterLinkMessage = () => providerContainer(
        tester,
      ).read(fakeActiveUserIdProvider.notifier).switchTo('@bob:example.org');

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick')));
      await tester.pumpAndSettle();

      expect(sent, hasLength(1));
      expect(linksSent, 0);
    });

    testWidgets('a cancel in Drive sends nothing', (tester) async {
      await pumpHost(tester);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel')));
      await tester.pumpAndSettle();

      expect(sent, isEmpty);
      expect(linksSent, 0);
      expect(find.text("Couldn't open Twake Drive"), findsNothing);
      expect(pickerState(tester), isA<DrivePickerIdle>());
    });

    testWidgets('the picker page uses the active theme surface', (
      tester,
    ) async {
      final theme = ThemeData.dark();
      await pumpHost(tester, theme: theme);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      final pageMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(DrivePickerPage),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(pageMaterial.color, theme.colorScheme.surface);
    });

    testWidgets('an error while the pick is handled is logged, says so and '
        'frees the picker', (tester) async {
      linksPolicy = _ThrowingLinksPolicy();
      await pumpHost(tester);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick')));
      await tester.pumpAndSettle();

      expect(failures, ['pick']);
      expect(sent, isEmpty);
      expect(find.text("Couldn't open Twake Drive"), findsOneWidget);
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drive-view')), findsOneWidget);
    });

    testWidgets('a failure in Drive says so and sends nothing', (tester) async {
      await pumpHost(tester);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fail')));
      await tester.pumpAndSettle();

      expect(sent, isEmpty);
      expect(linksSent, 0);
      expect(find.text("Couldn't open Twake Drive"), findsOneWidget);
    });

    testWidgets(
      'a page left with the back button sends nothing and frees the picker',
      (tester) async {
        await pumpHost(tester);
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(sent, isEmpty);
        expect(find.byKey(const Key('drive-view')), findsNothing);
        expect(pickerState(tester), isA<DrivePickerIdle>());
      },
    );

    testWidgets('shows the loading state while the sign-in runs, then opens '
        'the picker', (tester) async {
      final signedIn = Completer<void>();
      final inner = session.onObtain;
      session.onObtain = () async {
        await signedIn.future;
        return inner();
      };
      await pumpHost(tester);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pump();

      expect(signingInShown, isTrue);
      expect(find.byKey(const Key('drive-view')), findsNothing);

      signedIn.complete();
      await tester.pumpAndSettle();

      expect(signingInShown, isFalse);
      expect(signInRuns, 1);
      expect(find.byKey(const Key('drive-view')), findsOneWidget);
    });

    testWidgets(
      'an unexpected error while preparing says so and frees the picker',
      (tester) async {
        session.onObtain = () async => throw Exception('boom');
        await pumpHost(tester);

        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();

        expect(find.text("Couldn't open Twake Drive"), findsOneWidget);
        expect(failures, ['prepare']);
        expect(signingInShown, isFalse);
        expect(pickerState(tester), isA<DrivePickerIdle>());
      },
    );

    testWidgets(
      'a failed sign-in says so, opens no page and frees the picker',
      (tester) async {
        session.onObtain = () async =>
            throw const DriveSignInFailed(DriveSignInFailure.tokenEndpoint);
        await pumpHost(tester);

        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();

        expect(find.text("Couldn't sign in to Twake Drive"), findsOneWidget);
        expect(find.byKey(const Key('drive-view')), findsNothing);
        expect(pickerState(tester), isA<DrivePickerIdle>());
      },
    );

    testWidgets('a Drive that cannot be reached says so', (tester) async {
      session.onObtain = () async => throw const DriveIntentFailed();
      await pumpHost(tester);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't open Twake Drive"), findsOneWidget);
    });

    testWidgets('a Drive without the Chat app says who can fix it', (
      tester,
    ) async {
      session.onObtain = () async => throw const DriveChatAppMissing();
      await pumpHost(tester);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Twake Chat isn't installed on your Twake Drive yet. Ask your "
          'administrator to install it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a closed browser is silent', (tester) async {
      session.onObtain = () async => throw const DriveSignInCancelled();
      await pumpHost(tester);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't"), findsNothing);
      expect(find.byKey(const Key('drive-view')), findsNothing);
      expect(sent, isEmpty);
    });

    testWidgets('a second tap while the sign-in runs opens one page', (
      tester,
    ) async {
      final gate = Completer<DriveSession>();
      session.onObtain = () => gate.future;
      await pumpHost(tester);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('open')));
      await tester.pump();
      gate.complete(
        DriveSession(
          idToken: DriveIdToken(value: 't', expiresAt: DateTime.utc(2030)),
          platformUrl: Uri.parse('https://alice.twake.example'),
        ),
      );
      await tester.pumpAndSettle();

      expect(session.obtains, 1);
      expect(find.byKey(const Key('drive-view')), findsOneWidget);
    });

    testWidgets('a send that fails says so and does not clear the reply', (
      tester,
    ) async {
      sendError = Exception('offline');
      await pumpHost(tester);

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick')));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't open Twake Drive"), findsOneWidget);
      expect(linksSent, 0);
      expect(failures, ['sendLinks']);
    });

    testWidgets('an account switch closes the picker and leaves a sheet that '
        'was opened over it', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      final pickerContext = tester.element(find.byKey(const Key('drive-view')));
      unawaited(
        showModalBottomSheet<void>(
          context: pickerContext,
          builder: (_) => const SizedBox(key: Key('sheet'), height: 80),
        ),
      );
      await tester.pumpAndSettle();

      await switchAccount(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('drive-view')), findsNothing);
      expect(find.byKey(const Key('sheet')), findsOneWidget);
    });

    testWidgets('an account switch closes the picker of the old account and '
        'sends nothing', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drive-view')), findsOneWidget);

      await switchAccount(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('drive-view')), findsNothing);
      expect(sent, isEmpty);
      expect(filesSent, isEmpty);
      expect(pickerState(tester), isA<DrivePickerIdle>());
    });

    group('attach', () {
      Future<void> openAnd(WidgetTester tester, String key) async {
        await pumpHost(tester);
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
      }

      Future<List<String>> outcomesOf(List<DrivePendingFile> files) async => [
        for (final file in files)
          await file.ready.then(
            (saved) => saved.name,
            onError: (_) => 'failed',
          ),
      ];

      testWidgets('queues the files at once and hands each over when saved', (
        tester,
      ) async {
        await openAnd(tester, 'attach');

        expect(filesSent.single.map((f) => f.source.name), ['a.pdf', 'b.pdf']);
        expect(await outcomesOf(filesSent.single), ['a.pdf', 'b.pdf']);
        expect(downloads.askedMax, 5000);
        expect(sent, isEmpty);
        expect(find.textContaining("Couldn't"), findsNothing);
        expect(pickerState(tester), isA<DrivePickerIdle>());
      });

      testWidgets('shows the files at once and holds the user with no dialog', (
        tester,
      ) async {
        downloads.gate = Completer<void>();
        await pumpHost(tester);
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('attach')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Queued before a byte moved, and nothing covers the chat.
        expect(filesSent.single, hasLength(2));
        expect(find.byType(ProgressDialog), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
        // The queue owns the files: the picker is free for the next pick.
        expect(pickerState(tester), isA<DrivePickerIdle>());

        downloads.gate!.complete();
        await tester.pumpAndSettle();

        expect(await outcomesOf(filesSent.single), ['a.pdf', 'b.pdf']);
        expect(pickerState(tester), isA<DrivePickerIdle>());
      });

      testWidgets('opens Drive again while the files are still on their way', (
        tester,
      ) async {
        downloads.gate = Completer<void>();
        await pumpHost(tester);
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('attach')));
        await tester.pump();

        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('drive-view')), findsOneWidget);
        await tester.tap(find.byKey(const Key('cancel')));
        downloads.gate!.complete();
        await tester.pumpAndSettle();
        expect(await outcomesOf(filesSent.single), ['a.pdf', 'b.pdf']);
      });

      testWidgets('an account switch during the download keeps the files '
          'queued for the room they were picked in', (tester) async {
        downloads.gate = Completer<void>();
        await pumpHost(tester);
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('attach')));
        await tester.pump();
        expect(pickerState(tester), isA<DrivePickerIdle>());

        await switchAccount(tester);
        final newTicket = await startNewPick(tester);
        downloads.gate!.complete();
        await tester.pumpAndSettle();

        expect(await outcomesOf(filesSent.single), ['a.pdf', 'b.pdf']);
        expect(pickerState(tester), isA<DrivePickerOpen>());
        providerContainer(
          tester,
        ).read(drivePickerControllerProvider.notifier).release(newTicket);
      });

      testWidgets('a download that throws fails the queued files and logs it', (
        tester,
      ) async {
        downloads.error = const SocketException('connection reset');

        await openAnd(tester, 'attach');

        expect(await outcomesOf(filesSent.single), ['failed', 'failed']);
        expect(failures, ['download']);
        expect(pickerState(tester), isA<DrivePickerIdle>());
      });

      testWidgets('a queue that throws says so and downloads nothing', (
        tester,
      ) async {
        filesError = Exception('queue refused');

        await openAnd(tester, 'attach');

        expect(downloads.askedMax, isNull);
        expect(failures, ['sendFiles']);
        expect(
          find.text("Some files couldn't be added from Twake Drive"),
          findsOneWidget,
        );
        expect(pickerState(tester), isA<DrivePickerIdle>());
      });

      testWidgets('a failure on every file fails each of them', (tester) async {
        downloads.failing.addAll(['x.pdf', 'y.pdf']);

        await openAnd(tester, 'attach-bad');

        expect(await outcomesOf(filesSent.single), ['failed', 'failed']);
        expect(pickerState(tester), isA<DrivePickerIdle>());
      });

      testWidgets('a failure on some files fails only those and says so', (
        tester,
      ) async {
        downloads.failing.add('b.pdf');

        await openAnd(tester, 'attach');

        expect(await outcomesOf(filesSent.single), ['a.pdf', 'failed']);
        expect(
          find.text("Some files couldn't be added from Twake Drive"),
          findsOneWidget,
        );
      });

      testWidgets('a file that failed can be downloaded again for a retry', (
        tester,
      ) async {
        downloads.failing.add('b.pdf');
        await openAnd(tester, 'attach');
        downloads.failing.clear();

        final file = filesSent.single[1];
        final again = await tester.runAsync(file.again);

        expect(again?.name, 'b.pdf');
      });

      testWidgets(
        'a shortcut among the files is not attached and the user is told',
        (tester) async {
          await openAnd(tester, 'attach-mixed');

          expect(filesSent.single.map((f) => f.source.name), ['a.pdf']);
          expect(
            find.text("Shortcuts can't be attached, send a link instead"),
            findsOneWidget,
          );
        },
      );

      testWidgets('only shortcuts queues nothing and says so', (tester) async {
        await openAnd(tester, 'attach-shortcuts');

        expect(filesSent, isEmpty);
        expect(
          find.text("Shortcuts can't be attached, send a link instead"),
          findsOneWidget,
        );
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('asks Drive for the attach button with the upload limit', (
        tester,
      ) async {
        limit = 1234;
        await pumpHost(tester);

        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byKey(const Key('drive-view'))),
        );
        expect(
          container.read(drivePickerControllerProvider),
          isA<DrivePickerOpen>(),
        );
        await tester.tap(find.byKey(const Key('attach')));
        await tester.pumpAndSettle();
        expect(downloads.askedMax, 1234);
      });
    });
  });
}
