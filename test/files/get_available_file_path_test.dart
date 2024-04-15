import 'dart:io';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/manager/storage_directory_manager.dart';
import 'package:flutter_test/flutter_test.dart';

Future<File> createMockFile(String filePath) async {
  final file = File('$folderTestName/$filePath');
  await file.create(recursive: true);
  return file;
}

const folderTestName = 'generated';

void main() async {
  if (PlatformInfos.isWeb) {
    return;
  }
  test("""WHEN exist only one file in the folder,
          THEN the function should create another file with format fileName (1)
      """, () async {
    final file = await createMockFile('file1.pdf');
    final fileAvailable =
        await StorageDirectoryManager.instance.getAvailableFilePath(
      file.path,
    );
    await file.delete();
    expect(fileAvailable, '$folderTestName/file1 (1).pdf');
  });

  test("""WHEN exist only two files in the folder,
          THEN the function should create another file with format fileName (2)
      """, () async {
    final file = await createMockFile('file1.pdf');
    final file1 = await createMockFile('file1 (1).pdf');
    final fileAvailable =
        await StorageDirectoryManager.instance.getAvailableFilePath(
      file.path,
    );

    await Future.wait([
      file.delete(),
      file1.delete(),
    ]);
    expect(fileAvailable, '$folderTestName/file1 (2).pdf');
  });

  test("""WHEN exist only two files in the folder,
          THEN the function should create another file with format fileName (7)
      """, () async {
    final file = await createMockFile('file1.pdf');
    final file1 = await createMockFile('file1 (1).pdf');
    final file2 = await createMockFile('file1 (2).pdf');
    final file3 = await createMockFile('file1 (3).pdf');
    final file4 = await createMockFile('file1 (4).pdf');
    final file5 = await createMockFile('file1 (5).pdf');
    final file6 = await createMockFile('file1 (6).pdf');
    final fileAvailable =
        await StorageDirectoryManager.instance.getAvailableFilePath(
      file.path,
    );

    await Future.wait([
      file.delete(),
      file1.delete(),
      file2.delete(),
      file3.delete(),
      file4.delete(),
      file5.delete(),
      file6.delete(),
    ]);
    expect(fileAvailable, '$folderTestName/file1 (7).pdf');
  });

  test("""WHEN exist a file with name already have counter in the folder,
          THEN the function should create another file with format fileName (6) (1)
      """, () async {
    final file = await createMockFile('file1 (6).pdf');
    final fileAvailable =
        await StorageDirectoryManager.instance.getAvailableFilePath(
      file.path,
    );

    await Future.wait([
      file.delete(),
    ]);
    expect(fileAvailable, '$folderTestName/file1 (6) (1).pdf');
  });

  test("""WHEN exist a file that contains dot,
          THEN the function should create another file with format fileName (1)
      """, () async {
    final file = await createMockFile('my.document.v1.pdf');
    final fileAvailable =
        await StorageDirectoryManager.instance.getAvailableFilePath(
      file.path,
    );

    await Future.wait([
      file.delete(),
    ]);
    expect(fileAvailable, '$folderTestName/my.document.v1 (1).pdf');
  });

  test("""WHEN exist a file that contains no dot,
          THEN the function should create another file with format fileName (1)
      """, () async {
    final file = await createMockFile('text');
    final fileAvailable =
        await StorageDirectoryManager.instance.getAvailableFilePath(
      file.path,
    );

    await Future.wait([
      file.delete(),
    ]);
    expect(fileAvailable, '$folderTestName/text (1)');
  });

  test("""WHEN exist a file that start with a dot,
          THEN the function should create another file with format fileName (1)
      """, () async {
    final file = await createMockFile('.DS_Store');
    final fileAvailable =
        await StorageDirectoryManager.instance.getAvailableFilePath(
      file.path,
    );

    await Future.wait([
      file.delete(),
    ]);
    expect(fileAvailable, '$folderTestName/ (1).DS_Store');
  });

  test("""WHEN exist a file that have extension contains multiple dots,
          THEN the function should create another file with format fileName (1)
      """, () async {
    final file = await createMockFile('filename.tar.gz');
    final fileAvailable =
        await StorageDirectoryManager.instance.getAvailableFilePath(
      file.path,
    );

    await Future.wait([
      file.delete(),
    ]);
    expect(fileAvailable, '$folderTestName/filename.tar (1).gz');
  });

  test(
      """WHEN exist multiple files which have the same name and different counter,
          AND file name exists in the folder are file, file (1) and file (3),
          THEN the function should create another file with format fileName (2)
      """, () async {
    final file = await createMockFile('file.pdf');
    final file1 = await createMockFile('file (1).pdf');
    final file3 = await createMockFile('file (3).pdf');
    final fileAvailable =
        await StorageDirectoryManager.instance.getAvailableFilePath(
      file.path,
    );

    await Future.wait([
      file.delete(),
      file1.delete(),
      file3.delete(),
    ]);
    expect(fileAvailable, '$folderTestName/file (2).pdf');
  });

  final testDirectory = Directory(folderTestName);
  if (await testDirectory.exists()) {
    await testDirectory.delete();
  }
}
