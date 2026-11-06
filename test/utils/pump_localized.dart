import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

/// Pumps [child] in English, under [container].
Future<void> pumpLocalized(
  WidgetTester tester,
  ProviderContainer container,
  Widget child,
) => tester.pumpWidget(
  UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
      locale: const Locale('en'),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: child,
    ),
  ),
);
