// ignore_for_file: depend_on_referenced_packages

import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/retry_upload_result.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/mixins/upload_file_mixin.dart';
import 'package:twake_chat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'upload_file_mixin_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Room>(), MockSpec<UploadManager>()])
class _RetryUploadHost extends StatefulWidget {
  const _RetryUploadHost({required this.event});

  final Event event;

  @override
  State<_RetryUploadHost> createState() => _RetryUploadHostState();
}

class _RetryUploadHostState extends State<_RetryUploadHost>
    with UploadFileMixin<_RetryUploadHost> {
  @override
  Event get event => widget.event;

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: onRetryUpload, child: const Text('retry'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUploadManager uploadManager;
  late Event event;

  setUpAll(() {
    getIt.registerSingleton(ResponsiveUtils());
  });

  setUp(() {
    uploadManager = MockUploadManager();
    if (getIt.isRegistered<UploadManager>()) {
      getIt.unregister<UploadManager>();
    }
    getIt.registerSingleton<UploadManager>(uploadManager);
    event = Event(
      content: {'body': 'document.pdf', 'msgtype': 'm.file'},
      type: 'm.room.message',
      eventId: 'txid',
      senderId: '@bob:example.com',
      originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
      room: MockRoom(),
      status: EventStatus.error,
    );
  });

  Future<void> pumpAndTapRetry(WidgetTester tester) async {
    await tester.pumpWidget(
      ThemeBuilder(
        builder: (context, themeMode, primaryColor) => MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            LocaleNamesLocalizationsDelegate(),
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: LocalizationService.supportedLocales,
          theme: TwakeThemes.buildTheme(
            context,
            Brightness.light,
            primaryColor,
          ),
          home: Scaffold(body: _RetryUploadHost(event: event)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('retry'));
    await tester.pumpAndSettle();
  }

  group('UploadFileMixin::onRetryUpload()', () {
    testWidgets('\nWHEN the file data of a failed upload is gone.\n'
        'THEN a snackbar tells the user the message cannot be resent.\n', (
      tester,
    ) async {
      when(
        uploadManager.retryUpload(event),
      ).thenAnswer((_) async => RetryUploadResult.fileDataUnavailable);

      await pumpAndTapRetry(tester);

      expect(
        find.text(
          "This message can't be resent because its data is unavailable",
        ),
        findsOneWidget,
      );
    });

    testWidgets('\nWHEN the upload is retried successfully.\n'
        'THEN no snackbar is displayed.\n', (tester) async {
      when(
        uploadManager.retryUpload(event),
      ).thenAnswer((_) async => RetryUploadResult.started);

      await pumpAndTapRetry(tester);

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
