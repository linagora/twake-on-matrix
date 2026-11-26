import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/direct_chat/exceptions/create_direct_chat_exception.dart';
import 'package:twake_chat/data/direct_chat/repositories/direct_chat_repository_impl.provider.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/domain/model/file_info/image_file_info.dart';
import 'package:twake_chat/domain/usecase/room/unblock_user_interactor.dart';
import 'package:twake_chat/pages/chat/send_media_native_dialog/send_media_native_dialog.dart';
import 'package:twake_chat/pages/chat_draft/draft_chat.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_send_target.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _StubContacts extends ContactsController {
  @override
  Stream<List<UnifiedContact>> build() => Stream.value(const []);
}

class _ActiveClient extends Notifier<Client?> {
  @override
  Client? build() => null;

  // ignore: use_setters_to_change_properties
  void set(Client? client) => state = client;
}

final _activeClient = NotifierProvider<_ActiveClient, Client?>(
  _ActiveClient.new,
);

class _FakeRoom extends Fake implements Room {
  _FakeRoom(this.id);

  @override
  final String id;

  @override
  String get name => 'room';

  final sentTexts = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName != #sendTextEvent) {
      return super.noSuchMethod(invocation);
    }
    sentTexts.add(invocation.positionalArguments.first as String);
    return Future<String?>.value('event');
  }
}

class _FakeClient extends Fake implements Client {
  _FakeClient(this.byId);

  final Map<String, _FakeRoom> byId;

  @override
  Room? getRoomById(String id) => byId[id];
}

/// Each `createDirectChat` call waits on the next completer of [calls].
class _GatedRepository implements DirectChatRepository {
  final calls = <Completer<String>>[];
  var usable = true;

  @override
  Future<String> createDirectChat({required String contactMxId}) {
    final call = Completer<String>();
    calls.add(call);
    return call.future;
  }

  @override
  bool isUsableDirectChat({
    required String roomId,
    required String contactMxId,
  }) => usable;

  @override
  String? findDirectChat({required String contactMxId}) => null;
}

class _FakeUnblock extends Fake implements UnblockUserInteractor {}

class _FakeUpload extends Fake implements UploadManager {
  @override
  Future<void> failInterruptedUploads(Iterable<Event> events) async {}

  final uploads = <({Room room, List<FileInfo> files, String? caption})>[];
  Object? error;

  @override
  Future<void> uploadFileMobile({
    required Room room,
    required List<FileInfo> fileInfos,
    String? caption,
    Event? inReplyTo,
    ThreadSendTarget? thread,
  }) async {
    uploads.add((room: room, files: fileInfos, caption: caption));
    if (error != null) throw error!;
  }
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

class _FakeProgress extends Fake implements ReadProgress {}

class _FakeFile extends Fake implements DataReaderFile {
  _FakeFile(this.bytes);

  final Uint8List bytes;

  @override
  String? get fileName => 'copied.png';

  @override
  Future<Uint8List> readAll() async => bytes;
}

/// One clipboard item: a PNG image, or plain text.
class _FakeClipboardItem extends Fake implements ClipboardDataReader {
  _FakeClipboardItem.image(Uint8List this.bytes) : text = null;

  _FakeClipboardItem.text(String this.text) : bytes = null;

  final Uint8List? bytes;
  final String? text;

  DataFormat get _format => bytes != null ? Formats.png : Formats.plainText;

  @override
  List<DataFormat> getFormats(List<DataFormat> allFormats) =>
      allFormats.contains(_format) ? [_format] : const [];

  @override
  bool canProvide(DataFormat format) => format == _format;

  @override
  ReadProgress? getFile(
    FileFormat? format,
    AsyncValueChanged<DataReaderFile> onFile, {
    ValueChanged<Object>? onError,
    bool allowVirtualFiles = true,
    bool synthesizeFilesFromURIs = true,
  }) {
    if (format != _format) return null;
    onFile(_FakeFile(bytes!));
    return _FakeProgress();
  }

  @override
  ReadProgress? getValue<T extends Object>(
    ValueFormat<T> format,
    AsyncValueChanged<T?> onValue, {
    ValueChanged<Object>? onError,
  }) {
    if (format != _format) return null;
    onValue(text as T?);
    return _FakeProgress();
  }
}

class _TestDraft extends DraftChat {
  const _TestDraft({required super.contact});

  @override
  DraftChatController createState() => _TestController();
}

class _TestController extends DraftChatController {
  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: inputFocus, child: const Scaffold());
}

class _Harness {
  _Harness(this._tester) {
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        contactsControllerProvider.overrideWith(_StubContacts.new),
        activeMatrixClientProvider.overrideWith(
          (ref) => ref.watch(_activeClient),
        ),
        uploadManagerProvider.overrideWithValue(upload),
        directChatRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  final WidgetTester _tester;
  final repository = _GatedRepository();
  final upload = _FakeUpload();
  final visited = <String>[];
  late final ProviderContainer container;
  late final DraftChatController controller;

  Future<void> pump(Client client) async {
    getIt.registerSingleton<UnblockUserInteractor>(_FakeUnblock());
    getIt.registerSingleton<ResponsiveUtils>(ResponsiveUtils());
    container.read(_activeClient.notifier).set(client);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const _TestDraft(
            contact: PresentationContact(matrixId: '@bob:s'),
          ),
        ),
        GoRoute(
          path: '/rooms/:roomid',
          builder: (_, state) {
            visited.add(state.pathParameters['roomid']!);
            return const SizedBox();
          },
        ),
      ],
    );
    await _tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
        ),
      ),
    );
    controller = _tester.state<DraftChatController>(find.byType(_TestDraft));
  }

  /// Starts a send; the repository is then waiting on `repository.calls.last`.
  Future<void> send({OnRoomCreatedFailed onFailed}) async {
    await controller.sendText(onCreateRoomFailed: onFailed);
    await _tester.pump();
  }

  Future<void> settle() => _tester.pumpAndSettle();

  Future<void> unmount() => _tester.pumpWidget(const SizedBox());

  Completer<String> get lastCall => repository.calls.last;
}

Future<_Harness> _start(
  WidgetTester tester, {
  Map<String, _FakeRoom> rooms = const {},
}) async {
  final harness = _Harness(tester);
  addTearDown(getIt.reset);
  await harness.pump(_FakeClient(rooms));
  return harness;
}

void main() {
  group('a failed create request unblocks the screen', () {
    for (final failure in <Object>[
      const CreateDirectChatForbiddenException(),
      StateError('No active Matrix client'),
      ArgumentError('boom'),
    ]) {
      testWidgets('${failure.runtimeType}', (tester) async {
        final harness = await _start(tester);
        var failed = false;
        await harness.send(onFailed: () => failed = true);
        harness.controller.isSendingNotifier.value = true;

        harness.lastCall.completeError(failure);
        await harness.settle();

        expect(tester.takeException(), isNull);
        expect(failed, isTrue);
        expect(harness.controller.isSendingNotifier.value, isFalse);
        expect(harness.visited, isEmpty);
      });
    }
  });

  group('a request that is no longer current reports nothing', () {
    testWidgets('a newer request supersedes the older one', (tester) async {
      final harness = await _start(
        tester,
        rooms: {'!old:s': _FakeRoom('!old:s'), '!new:s': _FakeRoom('!new:s')},
      );
      var oldFailed = false;
      await harness.send(onFailed: () => oldFailed = true);
      final older = harness.lastCall;
      await harness.send();

      older.complete('!old:s');
      await harness.settle();
      expect(harness.visited, isEmpty);
      expect(oldFailed, isFalse);

      harness.lastCall.complete('!new:s');
      await harness.settle();
      expect(harness.visited, ['!new:s']);
    });

    testWidgets('a screen closed during the request is left alone', (
      tester,
    ) async {
      final harness = await _start(tester, rooms: {'!r:s': _FakeRoom('!r:s')});
      var failed = false;
      await harness.send(onFailed: () => failed = true);

      await harness.unmount();
      harness.lastCall.complete('!r:s');
      await harness.settle();

      expect(tester.takeException(), isNull);
      expect(failed, isFalse);
      expect(harness.visited, isEmpty);
    });

    testWidgets('an account switched during the request opens nothing', (
      tester,
    ) async {
      final harness = await _start(tester, rooms: {'!r:s': _FakeRoom('!r:s')});
      await harness.send();
      harness.controller.isSendingNotifier.value = true;

      harness.container.read(_activeClient.notifier).set(_FakeClient({}));
      harness.lastCall.complete('!r:s');
      await harness.settle();

      expect(harness.visited, isEmpty);
      expect(harness.controller.isSendingNotifier.value, isFalse);
    });
  });

  testWidgets('a created room is opened and receives the message', (
    tester,
  ) async {
    final room = _FakeRoom('!r:s');
    final harness = await _start(tester, rooms: {'!r:s': room});
    harness.controller.sendController.text = 'hello';
    await harness.send();

    harness.lastCall.complete('!r:s');
    await harness.settle();

    expect(harness.visited, ['!r:s']);
    expect(room.sentTexts, ['hello']);
  });

  testWidgets('a room that is not a usable chat with the contact is refused', (
    tester,
  ) async {
    final room = _FakeRoom('!r:s');
    final harness = await _start(tester, rooms: {'!r:s': room});
    harness.repository.usable = false;
    var failed = false;
    harness.controller.sendController.text = 'hello';
    await harness.send(onFailed: () => failed = true);
    harness.controller.isSendingNotifier.value = true;

    harness.lastCall.complete('!r:s');
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(harness.controller.isSendingNotifier.value, isFalse);
    expect(failed, isFalse);
    expect(harness.visited, isEmpty);
    expect(room.sentTexts, isEmpty);
  });

  testWidgets('a room the client no longer holds is refused', (tester) async {
    final harness = await _start(tester);
    var failed = false;
    await harness.send(onFailed: () => failed = true);
    harness.controller.isSendingNotifier.value = true;

    harness.lastCall.complete('!gone:s');
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(harness.controller.isSendingNotifier.value, isFalse);
    expect(failed, isFalse);
    expect(harness.visited, isEmpty);
  });

  testWidgets('a media request blocks the screen until it ends', (
    tester,
  ) async {
    final harness = await _start(tester);

    unawaited(harness.controller.sendVoiceMessageWeb());
    await tester.pump();

    expect(harness.controller.isSendingNotifier.value, isTrue);

    harness.lastCall.completeError(const CreateDirectChatForbiddenException());
    await harness.settle();

    expect(harness.controller.isSendingNotifier.value, isFalse);
  });

  group('an image pasted into the draft', () {
    late Directory tempDir;
    late PathProviderPlatform originalPathProvider;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('draft_paste_test');
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    });

    tearDown(() {
      PathProviderPlatform.instance = originalPathProvider;
      tempDir.deleteSync(recursive: true);
    });

    final pasted = [
      MatrixImageFile(
        bytes: Uint8List.fromList([1, 2, 3]),
        name: 'copied',
        mimeType: 'image/png',
      ),
    ];

    // Writing the pasted image to a file is real I/O, so the steps run in
    // `runAsync` and wait on real time.
    Future<void> waitUntil(bool Function() condition) => Future(() async {
      while (!condition()) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }).timeout(const Duration(seconds: 5));

    Future<void> runPaste(
      WidgetTester tester,
      _Harness harness, {
      required void Function() onCreateCall,
      required bool Function() done,
    }) => tester.runAsync(() async {
      unawaited(harness.controller.onPasteImages(pasted));
      await waitUntil(() => harness.repository.calls.isNotEmpty);
      expect(harness.controller.sendController.text, isEmpty);
      onCreateCall();
      await waitUntil(done);
    });

    void sendFromPreview(_Harness harness) =>
        harness.controller.mediaCaptionDialogPresenter =
            (context, {required files, room, pendingText}) async =>
                SendMediaNativeResult(files: files, caption: pendingText);

    testWidgets('creates the room and sends the image with the draft text', (
      tester,
    ) async {
      final room = _FakeRoom('!r:s');
      final harness = await _start(tester, rooms: {'!r:s': room});
      harness.controller.sendController.text = 'look';
      sendFromPreview(harness);

      await runPaste(
        tester,
        harness,
        onCreateCall: () => harness.lastCall.complete('!r:s'),
        done: () => harness.upload.uploads.isNotEmpty,
      );
      await harness.settle();

      expect(harness.visited, ['!r:s']);
      final upload = harness.upload.uploads.single;
      expect(upload.room, room);
      expect(upload.caption, 'look');
      expect(upload.files.single, isA<ImageFileInfo>());
    });

    testWidgets('a failed upload still opens the room', (tester) async {
      final harness = await _start(tester, rooms: {'!r:s': _FakeRoom('!r:s')});
      harness.upload.error = StateError('upload failed');
      sendFromPreview(harness);

      await runPaste(
        tester,
        harness,
        onCreateCall: () => harness.lastCall.complete('!r:s'),
        done: () => harness.upload.uploads.isNotEmpty,
      );
      await harness.settle();

      expect(tester.takeException(), isNull);
      expect(harness.visited, ['!r:s']);
    });

    testWidgets('a failed room creation gives the caption back', (
      tester,
    ) async {
      final harness = await _start(tester);
      harness.controller.sendController.text = 'look';
      sendFromPreview(harness);

      await runPaste(
        tester,
        harness,
        onCreateCall: () => harness.lastCall.completeError(
          const CreateDirectChatForbiddenException(),
        ),
        done: () => harness.controller.sendController.text.isNotEmpty,
      );
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(harness.controller.sendController.text, 'look');
      expect(harness.controller.inputText.value, 'look');
      expect(harness.controller.isSendingNotifier.value, isFalse);
      expect(harness.upload.uploads, isEmpty);
      expect(harness.visited, isEmpty);
    });

    testWidgets('creates nothing when the preview is cancelled', (
      tester,
    ) async {
      final harness = await _start(tester);
      harness.controller.sendController.text = 'look';
      harness.controller.mediaCaptionDialogPresenter =
          (context, {required files, room, pendingText}) async => null;

      await tester.runAsync(() => harness.controller.onPasteImages(pasted));

      expect(harness.repository.calls, isEmpty);
      expect(harness.upload.uploads, isEmpty);
      expect(harness.controller.sendController.text, 'look');
    });

    testWidgets('a screen closed during the preview creates nothing', (
      tester,
    ) async {
      final harness = await _start(tester);
      final previewOpened = Completer<List<FileInfo>>();
      final previewClosed = Completer<void>();
      harness.controller.mediaCaptionDialogPresenter =
          (context, {required files, room, pendingText}) async {
            previewOpened.complete(files);
            await previewClosed.future;
            return SendMediaNativeResult(files: files);
          };
      var pasteDone = false;

      unawaited(
        harness.controller.onPasteImages(pasted).then((_) => pasteDone = true),
      );
      // The paste runs in the test zone, so its file I/O needs real time and
      // a pump to move on.
      for (var i = 0; !previewOpened.isCompleted; i++) {
        if (i == 500) fail('The preview never opened');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await harness.unmount();
      previewClosed.complete();
      await tester.pump();

      expect(pasteDone, isTrue);
      expect(tester.takeException(), isNull);
      expect(harness.repository.calls, isEmpty);
      expect(harness.upload.uploads, isEmpty);
    });
  });

  testWidgets('text set without typing, like a paste, shows the send button', (
    tester,
  ) async {
    final harness = await _start(tester);

    harness.controller.sendController.text = 'pasted';

    expect(harness.controller.inputText.value, 'pasted');
  });

  group('the paste from the iOS menu', () {
    late Directory tempDir;
    late PathProviderPlatform originalPathProvider;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('draft_menu_paste_test');
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    });

    tearDown(() {
      PathProviderPlatform.instance = originalPathProvider;
      tempDir.deleteSync(recursive: true);
    });

    Future<_Harness> startFocused(WidgetTester tester) async {
      final harness = await _start(tester);
      harness.controller.inputFocus.requestFocus();
      await tester.pump();
      return harness;
    }

    testWidgets('opens the preview for an image', (tester) async {
      final harness = await startFocused(tester);
      List<FileInfo>? previewed;
      harness.controller.mediaCaptionDialogPresenter =
          (context, {required files, room, pendingText}) async {
            previewed = files;
            return null;
          };

      await tester.runAsync(
        () => harness.controller.pasteFromClipboard(
          () async => ClipboardReader([
            _FakeClipboardItem.image(Uint8List.fromList([1, 2, 3])),
          ]),
        ),
      );

      expect(previewed, hasLength(1));
      expect(previewed!.single.mimeType, 'image/png');
      expect(harness.controller.sendController.text, isEmpty);
    });

    testWidgets('inserts text and shows the send button', (tester) async {
      final harness = await startFocused(tester);
      var previewOpened = false;
      harness.controller.mediaCaptionDialogPresenter =
          (context, {required files, room, pendingText}) async {
            previewOpened = true;
            return null;
          };

      await tester.runAsync(
        () => harness.controller.pasteFromClipboard(
          () async => ClipboardReader([_FakeClipboardItem.text('hello')]),
        ),
      );

      expect(harness.controller.sendController.text, 'hello');
      expect(harness.controller.inputText.value, 'hello');
      expect(previewOpened, isFalse);
    });

    testWidgets('leaves the clipboard alone when the field is not focused', (
      tester,
    ) async {
      final harness = await _start(tester);
      var read = false;

      await harness.controller.pasteFromClipboard(() async {
        read = true;
        return ClipboardReader(const []);
      });

      expect(read, isFalse);
      expect(harness.controller.sendController.text, isEmpty);
    });

    testWidgets('tells the user when the clipboard cannot be read', (
      tester,
    ) async {
      final harness = await startFocused(tester);

      await tester.runAsync(
        () => harness.controller.pasteFromClipboard(
          () => Future.error(StateError('clipboard')),
        ),
      );
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
