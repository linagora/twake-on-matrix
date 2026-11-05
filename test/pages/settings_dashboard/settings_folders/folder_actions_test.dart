import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/exception/spaces/folder_exception.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/folder_actions.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../../utils/pump_localized.dart';

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  group('runFolderAction', () {
    Future<BuildContext> pump(WidgetTester tester) async {
      await pumpLocalized(
        tester,
        ProviderContainer.test(retry: (_, _) => null),
        const Scaffold(body: Text('screen')),
      );
      return tester.element(find.text('screen'));
    }

    testWidgets('whenTheSaveFails_tellsItAndAnswersFalse', (tester) async {
      final context = await pump(tester);

      final isDone = await runFolderAction(
        context,
        () async => throw const FolderSaveFailedException(),
      );
      await tester.pump();

      expect(isDone, isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('whenTheScreenIsGone_stillAnswersFalse', (tester) async {
      final context = await pump(tester);
      final run = runFolderAction(context, () async {
        await tester.pumpWidget(const SizedBox());
        throw const FolderSaveFailedException();
      });

      expect(await run, isFalse);
    });

    testWidgets('whenTheActionWorks_answersTrue', (tester) async {
      final context = await pump(tester);

      expect(await runFolderAction(context, () async {}), isTrue);
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
