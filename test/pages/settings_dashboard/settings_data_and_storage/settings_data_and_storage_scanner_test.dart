import 'package:fluffychat/pages/settings_dashboard/settings_data_and_storage/settings_data_and_storage_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageCategory.fromFile', () {
    group('stickers', () {
      test('classifies .tgs as stickers', () {
        expect(
          StorageCategory.fromFile('/cache/anim.tgs'),
          StorageCategory.stickers,
        );
      });

      test('classifies .lottie as stickers', () {
        expect(
          StorageCategory.fromFile('/cache/anim.lottie'),
          StorageCategory.stickers,
        );
      });

      test(
        'classifies path containing "sticker" as stickers regardless of ext',
        () {
          expect(
            StorageCategory.fromFile('/cache/sticker_pack/image.png'),
            StorageCategory.stickers,
          );
        },
      );

      test('path with "Sticker" (uppercase) is matched case-insensitively', () {
        expect(
          StorageCategory.fromFile('/cache/Sticker/foo.webp'),
          StorageCategory.stickers,
        );
      });
    });

    group('medias', () {
      test('classifies .jpg as medias', () {
        expect(
          StorageCategory.fromFile('/cache/photo.jpg'),
          StorageCategory.medias,
        );
      });

      test('classifies .png as medias', () {
        expect(
          StorageCategory.fromFile('/cache/img.png'),
          StorageCategory.medias,
        );
      });

      test('classifies .webp as medias', () {
        expect(
          StorageCategory.fromFile('/cache/img.webp'),
          StorageCategory.medias,
        );
      });

      test('classifies .heic as medias', () {
        expect(
          StorageCategory.fromFile('/cache/photo.heic'),
          StorageCategory.medias,
        );
      });
    });

    group('videos', () {
      test('classifies .mp4 as videos', () {
        expect(
          StorageCategory.fromFile('/cache/clip.mp4'),
          StorageCategory.videos,
        );
      });

      test('classifies .mov as videos', () {
        expect(
          StorageCategory.fromFile('/cache/clip.mov'),
          StorageCategory.videos,
        );
      });

      test('classifies .mkv as videos', () {
        expect(
          StorageCategory.fromFile('/cache/clip.mkv'),
          StorageCategory.videos,
        );
      });
    });

    group('files', () {
      test('classifies .pdf as files', () {
        expect(
          StorageCategory.fromFile('/cache/doc.pdf'),
          StorageCategory.files,
        );
      });

      test('classifies .docx as files', () {
        expect(
          StorageCategory.fromFile('/cache/doc.docx'),
          StorageCategory.files,
        );
      });

      test('classifies .zip as files', () {
        expect(
          StorageCategory.fromFile('/cache/archive.zip'),
          StorageCategory.files,
        );
      });

      test('classifies .txt as files', () {
        expect(
          StorageCategory.fromFile('/cache/note.txt'),
          StorageCategory.files,
        );
      });
    });

    group('other', () {
      test('classifies unknown extension as other', () {
        expect(
          StorageCategory.fromFile('/cache/binary.bin'),
          StorageCategory.other,
        );
      });

      test('classifies no-extension file as other', () {
        expect(StorageCategory.fromFile('/cache/noext'), StorageCategory.other);
      });

      test('classifies .dart source as other', () {
        expect(
          StorageCategory.fromFile('/cache/main.dart'),
          StorageCategory.other,
        );
      });
    });

    group('priority: stickers > medias', () {
      test('sticker-path with image ext resolves to stickers, not medias', () {
        // .jpg is a media extension, but the path contains "sticker"
        expect(
          StorageCategory.fromFile('/cache/sticker/image.jpg'),
          StorageCategory.stickers,
        );
      });

      test('sticker-path with video ext resolves to stickers, not videos', () {
        expect(
          StorageCategory.fromFile('/cache/sticker/clip.mp4'),
          StorageCategory.stickers,
        );
      });
    });
  });
}
