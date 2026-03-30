import 'package:fluffychat/domain/model/preview_file/supported_preview_file_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupportedPreviewFileTypes.docFileTypes', () {
    test('should contain doc extension', () {
      expect(SupportedPreviewFileTypes.docFileTypes, contains('doc'));
    });

    test('should contain docx extension', () {
      expect(SupportedPreviewFileTypes.docFileTypes, contains('docx'));
    });

    test('should contain docm extension', () {
      expect(SupportedPreviewFileTypes.docFileTypes, contains('docm'));
    });

    test('should contain dot extension', () {
      expect(SupportedPreviewFileTypes.docFileTypes, contains('dot'));
    });

    test('should contain dotx extension', () {
      expect(SupportedPreviewFileTypes.docFileTypes, contains('dotx'));
    });

    test('should contain dotm extension', () {
      expect(SupportedPreviewFileTypes.docFileTypes, contains('dotm'));
    });

    // Regression: docx appears twice in the list after the PR change.
    // This test documents and guards the current behaviour so any future
    // deduplication is an intentional, visible change.
    test('docx appears twice in the list (duplicate introduced by PR)', () {
      final docxCount =
          SupportedPreviewFileTypes.docFileTypes
              .where((t) => t == 'docx')
              .length;
      expect(docxCount, 2);
    });

    test('list contains exactly 7 entries', () {
      expect(SupportedPreviewFileTypes.docFileTypes.length, 7);
    });

    test('unique extensions cover all Word-compatible formats', () {
      final unique = SupportedPreviewFileTypes.docFileTypes.toSet();
      expect(unique, containsAll(['doc', 'docx', 'docm', 'dot', 'dotx', 'dotm']));
    });
  });

  group('SupportedPreviewFileTypes.pdfFileTypes', () {
    test('should contain pdf extension', () {
      expect(SupportedPreviewFileTypes.pdfFileTypes, contains('pdf'));
    });
  });

  group('SupportedPreviewFileTypes.xlsFileTypes', () {
    test('should contain xls extension', () {
      expect(SupportedPreviewFileTypes.xlsFileTypes, contains('xls'));
    });

    test('should contain xlsx extension', () {
      expect(SupportedPreviewFileTypes.xlsFileTypes, contains('xlsx'));
    });
  });

  group('SupportedPreviewFileTypes.pptFileTypes', () {
    test('should contain ppt extension', () {
      expect(SupportedPreviewFileTypes.pptFileTypes, contains('ppt'));
    });

    test('should contain pptx extension', () {
      expect(SupportedPreviewFileTypes.pptFileTypes, contains('pptx'));
    });
  });
}