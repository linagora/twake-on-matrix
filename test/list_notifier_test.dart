import 'package:fluffychat/presentation/list_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

void main() {
  group('ListNotifier', () {
    late ListNotifier<MatrixFile> listNotifier;

    setUp(() {
      listNotifier = ListNotifier<MatrixFile>([
        MatrixFile(
          name: 'test1.png',
          bytes: null,
          readStream: Stream.value([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
          mimeType: 'image/png',
        ),
        MatrixFile(
          name: 'test2.png',
          bytes: null,
          readStream: Stream.value([10, 11, 12, 13, 14, 15, 16, 17, 18, 19]),
          mimeType: 'image/pdf',
        ),
        MatrixFile(
          name: 'test3.png',
          bytes: null,
          readStream: Stream.value([20, 21, 22, 23, 24, 25, 26, 27, 28, 29]),
          mimeType: 'image/png',
        ),
      ]);
    });

    test('remove should remove the specified MatrixFile from the list', () {
      final matrixFiles = listNotifier.value;
      final lastFile = matrixFiles[2];
      int notificationCount = 0;
      listNotifier.addListener(() => notificationCount++);

      expect(listNotifier.remove(matrixFiles[1]), isTrue);

      expect(listNotifier.value, equals([matrixFiles[0], lastFile]));
      expect(notificationCount, equals(1));
    });

    test('add should add the MatrixFile to the list', () {
      int notificationCount = 0;
      listNotifier.addListener(() => notificationCount++);
      final matrixFiles = List.from(listNotifier.value);
      final newFile = MatrixFile(
        name: 'test4.png',
        bytes: null,
        readStream: Stream.value([30, 31, 32, 33, 34, 35, 36, 37, 38, 39]),
        mimeType: 'image/png',
      );
      listNotifier.add(newFile);

      expect(
        listNotifier.value,
        equals(<MatrixFile>[
          ...matrixFiles,
          newFile,
        ]),
      );
      expect(notificationCount, equals(1));
    });

    test('notify should notify the listeners', () {
      int notificationCount = 0;
      listNotifier.addListener(() => notificationCount++);
      listNotifier.notify();
      expect(notificationCount, equals(1));
    });

    test('update should update the old value with the new value', () {
      int notificationCount = 0;
      listNotifier.addListener(() => notificationCount++);
      final matrixFile = listNotifier.value[2];
      final replaceFile = MatrixFile(
        name: 'test5.png',
        bytes: null,
        readStream: Stream.value([50, 51, 52, 53, 54, 55, 56, 57, 58, 59]),
        mimeType: 'image/jpeg',
      );

      listNotifier.update(matrixFile, replaceFile);

      expect(
        listNotifier.value,
        equals(<MatrixFile>[
          ...listNotifier.value.getRange(0, 2),
          replaceFile,
        ]),
      );
      expect(notificationCount, equals(1));
    });
  });
}
