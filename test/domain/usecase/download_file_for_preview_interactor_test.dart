import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:twake_chat/domain/app_state/preview_file/download_file_for_preview_success.dart';
import 'package:twake_chat/domain/usecase/download_file_for_preview_interactor.dart';

import 'download_file_for_preview_interactor_test.mocks.dart';

@GenerateMocks([Event])
void main() {
  late Directory tempDir;
  late String previewDirPath;
  late MockEvent event;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('preview_interactor_test');
    previewDirPath = p.join(tempDir.path, 'a', 'b');
    event = MockEvent();
    when(event.content).thenReturn({'filename': '../../x'});
    when(event.body).thenReturn('../../x');
    when(
      event.downloadAndDecryptAttachment(
        downloadCallback: anyNamed('downloadCallback'),
        getThumbnail: anyNamed('getThumbnail'),
      ),
    ).thenAnswer(
      (_) async => MatrixFile(bytes: Uint8List.fromList([1]), name: '../../x'),
    );
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('execute_whenNameHasPathSeparators_keepsOnlyTheLastName', () async {
    // Act
    final states = await DownloadFileForPreviewInteractor()
        .execute(event: event, tempDirPath: previewDirPath)
        .toList();
    final success =
        states.last.getOrElse(() => throw states.last)
            as DownloadFileForPreviewSuccess;

    // Assert
    expect(
      success.downloadFileForPreviewResponse.filePath,
      p.join(previewDirPath, 'x'),
    );
  });
}
