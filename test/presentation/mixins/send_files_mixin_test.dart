import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/file_info/image_file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:fluffychat/pages/chat/send_media_native_dialog/send_media_native_dialog.dart';
import 'package:fluffychat/presentation/mixins/send_files_mixin.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'send_files_mixin_test.mocks.dart';

class _TestSendFilesMixin with SendFilesMixin {}

/// Fake platform so `ImagePicker().pickMultipleMedia()` returns a controlled
/// list of files without touching the native PHPicker.
class _FakeImagePickerPlatform extends ImagePickerPlatform {
  List<XFile> media = [];
  Object? error;

  @override
  Future<List<XFile>> getMedia({required MediaOptions options}) async {
    if (error != null) throw error!;
    return media;
  }
}

@GenerateNiceMocks([
  MockSpec<UploadManager>(),
  MockSpec<Client>(),
  MockSpec<Event>(),
])
void main() {
  late _TestSendFilesMixin mixin;
  late MockUploadManager uploadManager;
  late _FakeImagePickerPlatform fakePicker;
  late ImagePickerPlatform originalPicker;
  late Room room;

  // Drives the post-pick caption dialog without a real widget tree. Returns the
  // picked files unchanged with the prefilled draft as caption, simulating the
  // user pressing "send". Overridden per-test for the cancel case.
  SendMediaNativeResult? Function(List<FileInfo>, String?) dialogOutcome =
      (files, pendingText) =>
          SendMediaNativeResult(files: files, caption: pendingText);

  setUp(() {
    mixin = _TestSendFilesMixin();
    mixin.mediaCaptionDialogPresenter =
        (context, {required files, room, pendingText}) async =>
            dialogOutcome(files, pendingText);
    uploadManager = MockUploadManager();
    fakePicker = _FakeImagePickerPlatform();
    originalPicker = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = fakePicker;
    getIt.registerSingleton<UploadManager>(uploadManager);
    room = Room(client: MockClient(), id: '!room:server.abc');
  });

  tearDown(() async {
    ImagePickerPlatform.instance = originalPicker;
    dialogOutcome = (files, pendingText) =>
        SendMediaNativeResult(files: files, caption: pendingText);
    await getIt.reset();
  });

  /// Pumps a trivial widget and invokes [body] with a live [BuildContext], which
  /// `pickAndSendMediaNative` now requires to present the caption dialog.
  Future<void> withContext(
    WidgetTester tester,
    Future<void> Function(BuildContext context) body,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await body(capturedContext);
  }

  group('pickAndSendMediaNative', () {
    testWidgets(
      'maps picked files to typed FileInfo and calls uploadFileMobile',
      (tester) async {
        // Distinct name vs path so a swapped mapping would fail the assertion.
        fakePicker.media = [
          XFile('uploads/photo.jpg'),
          XFile('uploads/clip.mp4'),
        ];
        final replyEvent = MockEvent();
        var callbackCalled = false;

        await withContext(tester, (context) async {
          await mixin.pickAndSendMediaNative(
            context,
            room: room,
            caption: 'hello',
            inReplyTo: replyEvent,
            onSendCallback: () => callbackCalled = true,
          );
        });

        final captured =
            verify(
                  uploadManager.uploadFileMobile(
                    room: room,
                    fileInfos: captureAnyNamed('fileInfos'),
                    caption: 'hello',
                    inReplyTo: replyEvent,
                  ),
                ).captured.single
                as List<FileInfo>;

        expect(captured, hasLength(2));
        // Image → ImageFileInfo so the HEIC/thumbnail pipeline runs downstream.
        expect(
          captured[0],
          isA<ImageFileInfo>()
              .having((f) => f.fileName, 'fileName', 'photo.jpg')
              .having((f) => f.filePath, 'filePath', 'uploads/photo.jpg'),
        );
        // Video → VideoFileInfo.
        expect(
          captured[1],
          isA<VideoFileInfo>()
              .having((f) => f.fileName, 'fileName', 'clip.mp4')
              .having((f) => f.filePath, 'filePath', 'uploads/clip.mp4'),
        );
        expect(callbackCalled, isTrue);
      },
    );

    testWidgets('does nothing when the picker returns no files', (
      tester,
    ) async {
      fakePicker.media = [];
      var callbackCalled = false;

      await withContext(tester, (context) async {
        await mixin.pickAndSendMediaNative(
          context,
          room: room,
          onSendCallback: () => callbackCalled = true,
        );
      });

      verifyNever(
        uploadManager.uploadFileMobile(
          room: anyNamed('room'),
          fileInfos: anyNamed('fileInfos'),
          caption: anyNamed('caption'),
          inReplyTo: anyNamed('inReplyTo'),
        ),
      );
      expect(callbackCalled, isFalse);
    });

    testWidgets('does nothing when the user cancels the caption dialog', (
      tester,
    ) async {
      fakePicker.media = [XFile('uploads/photo.jpg')];
      dialogOutcome = (_, __) => null; // user dismissed the sheet
      var callbackCalled = false;

      await withContext(tester, (context) async {
        await mixin.pickAndSendMediaNative(
          context,
          room: room,
          onSendCallback: () => callbackCalled = true,
        );
      });

      verifyNever(
        uploadManager.uploadFileMobile(
          room: anyNamed('room'),
          fileInfos: anyNamed('fileInfos'),
          caption: anyNamed('caption'),
          inReplyTo: anyNamed('inReplyTo'),
        ),
      );
      expect(callbackCalled, isFalse);
    });

    testWidgets(
      'sends only the files kept in the dialog (removed ones are dropped)',
      (tester) async {
        fakePicker.media = [
          XFile('uploads/photo.jpg'),
          XFile('uploads/clip.mp4'),
        ];
        // Simulate the user removing the video before sending.
        dialogOutcome = (files, pendingText) => SendMediaNativeResult(
          files: files.where((f) => f is! VideoFileInfo).toList(),
          caption: pendingText,
        );

        await withContext(tester, (context) async {
          await mixin.pickAndSendMediaNative(context, room: room);
        });

        final captured =
            verify(
                  uploadManager.uploadFileMobile(
                    room: room,
                    fileInfos: captureAnyNamed('fileInfos'),
                    caption: anyNamed('caption'),
                    inReplyTo: anyNamed('inReplyTo'),
                  ),
                ).captured.single
                as List<FileInfo>;

        expect(captured, hasLength(1));
        expect(captured.single, isA<ImageFileInfo>());
      },
    );

    testWidgets(
      'maps an unknown file type to a bare FileInfo (not Image/Video)',
      (tester) async {
        fakePicker.media = [XFile('uploads/report.pdf')];

        await withContext(tester, (context) async {
          await mixin.pickAndSendMediaNative(context, room: room);
        });

        final captured =
            verify(
                  uploadManager.uploadFileMobile(
                    room: room,
                    fileInfos: captureAnyNamed('fileInfos'),
                    caption: anyNamed('caption'),
                    inReplyTo: anyNamed('inReplyTo'),
                  ),
                ).captured.single
                as List<FileInfo>;

        expect(captured, hasLength(1));
        expect(captured.single, isA<FileInfo>());
        expect(captured.single, isNot(isA<ImageFileInfo>()));
        expect(captured.single, isNot(isA<VideoFileInfo>()));
        expect(captured.single.fileName, 'report.pdf');
      },
    );

    testWidgets(
      'swallows picker errors without uploading, calling back, or rethrowing',
      (tester) async {
        var callbackCalled = false;

        await withContext(tester, (context) async {
          for (final error in <Object>[
            PlatformException(code: 'cancelled'),
            Exception('unexpected plugin failure'),
          ]) {
            fakePicker.error = error;

            // Must not rethrow on this user-triggered path.
            await mixin.pickAndSendMediaNative(
              context,
              room: room,
              onSendCallback: () => callbackCalled = true,
            );
          }
        });

        verifyNever(
          uploadManager.uploadFileMobile(
            room: anyNamed('room'),
            fileInfos: anyNamed('fileInfos'),
            caption: anyNamed('caption'),
            inReplyTo: anyNamed('inReplyTo'),
          ),
        );
        expect(callbackCalled, isFalse);
      },
    );

    testWidgets('does nothing when room is null', (tester) async {
      fakePicker.media = [XFile('uploads/photo.jpg')];
      var callbackCalled = false;

      await withContext(tester, (context) async {
        await mixin.pickAndSendMediaNative(
          context,
          room: null,
          onSendCallback: () => callbackCalled = true,
        );
      });

      verifyNever(
        uploadManager.uploadFileMobile(
          room: anyNamed('room'),
          fileInfos: anyNamed('fileInfos'),
          caption: anyNamed('caption'),
          inReplyTo: anyNamed('inReplyTo'),
        ),
      );
      expect(callbackCalled, isFalse);
    });
  });
}
