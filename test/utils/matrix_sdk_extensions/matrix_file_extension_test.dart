import 'dart:typed_data';

import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart'; // Adjust based on where MatrixFile is defined

void main() {
  group('MatrixFileExtension', () {
    test('should return true for valid image MIME type', () {
      final file = MatrixFile(
        name: 'image.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List(0),
      );
      expect(file.isImage(), isTrue);
    });

    test('should return true for valid image file extension', () {
      final file = MatrixFile(
        name: 'image.png',
        mimeType: null,
        bytes: Uint8List(0),
      );
      expect(file.isImage(), isTrue);
    });

    test(
      'should return true for valid image file extension with null MIME type',
      () {
        final file = MatrixFile(
          name: 'image.gif',
          mimeType: null,
          bytes: Uint8List(0),
        );
        expect(file.isImage(), isTrue);
      },
    );

    test('should return false for non-image MIME type', () {
      final file = MatrixFile(
        name: 'document.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List(0),
      );
      expect(file.isImage(), isFalse);
    });

    test('should return false for non-image file extension', () {
      final file = MatrixFile(
        name: 'document.txt',
        mimeType: null,
        bytes: Uint8List(0),
      );
      expect(file.isImage(), isFalse);
    });

    test('should return false for file with no extension', () {
      final file = MatrixFile(
        name: 'file_without_extension',
        mimeType: null,
        bytes: Uint8List(0),
      );
      expect(file.isImage(), isFalse);
    });

    test('should return false for empty file name', () {
      final file = MatrixFile(name: '', mimeType: null, bytes: Uint8List(0));
      expect(file.isImage(), isFalse);
    });
  });
}
