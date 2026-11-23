import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.downloads);

  final String? downloads;

  @override
  Future<String?> getDownloadsPath() async => downloads;
}

void main() {
  late Directory downloads;
  late PathProviderPlatform originalPathProvider;

  // The snackbar reads its width from ResponsiveUtils in GetIt.
  setUpAll(() => GetIt.instance.registerSingleton(ResponsiveUtils()));
  tearDownAll(GetIt.instance.reset);

  setUp(() {
    downloads = Directory.systemTemp.createTempSync('downloads_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(downloads.path);
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPathProvider;
    downloads.deleteSync(recursive: true);
  });

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return context;
  }

  Future<String?> download(WidgetTester tester, MatrixFile file) async {
    final context = await pumpHost(tester);
    final result = await tester.runAsync(
      () => file.downloadFileOnDesktop(context),
    );
    await tester.pump();
    return result;
  }

  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  group('Download a file on desktop', () {
    testWidgets(
      'a new file is written into Downloads under its name and the full path is returned',
      (tester) async {
        final result = await download(
          tester,
          MatrixFile(
            bytes: bytes,
            name: 'report.pdf',
            mimeType: 'application/pdf',
          ),
        );

        final expected = p.join(downloads.path, 'report.pdf');
        expect(result, expected);
        expect(File(expected).readAsBytesSync(), bytes);
      },
    );

    testWidgets('a snackbar tells the user the file is saved to Downloads', (
      tester,
    ) async {
      await download(
        tester,
        MatrixFile(
          bytes: bytes,
          name: 'report.pdf',
          mimeType: 'application/pdf',
        ),
      );

      expect(find.text('File saved to Downloads'), findsOneWidget);
    });

    testWidgets(
      'an existing file with the same name is kept and the new one gets the next free name',
      (tester) async {
        final existing = File(p.join(downloads.path, 'report.pdf'))
          ..writeAsBytesSync([9, 9, 9]);

        final result = await download(
          tester,
          MatrixFile(
            bytes: bytes,
            name: 'report.pdf',
            mimeType: 'application/pdf',
          ),
        );

        expect(existing.readAsBytesSync(), [9, 9, 9]);
        final expected = p.join(downloads.path, 'report (1).pdf');
        expect(result, expected);
        expect(File(expected).readAsBytesSync(), bytes);
      },
    );

    testWidgets('a name already ending with its extension is not doubled', (
      tester,
    ) async {
      final result = await download(
        tester,
        MatrixFile(bytes: bytes, name: 'photo.png', mimeType: 'image/png'),
      );

      expect(result, p.join(downloads.path, 'photo.png'));
      expect(File(p.join(downloads.path, 'photo.png')).existsSync(), isTrue);
      expect(
        File(p.join(downloads.path, 'photo.png.png')).existsSync(),
        isFalse,
      );
    });

    testWidgets('returns null when the Downloads folder is unavailable', (
      tester,
    ) async {
      PathProviderPlatform.instance = _FakePathProvider(null);

      final result = await download(
        tester,
        MatrixFile(
          bytes: bytes,
          name: 'report.pdf',
          mimeType: 'application/pdf',
        ),
      );

      expect(result, isNull);
    });
  });
}
