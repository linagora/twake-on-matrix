import 'package:fluffychat/pages/new_private_chat/widget/contact_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

void main() {
  group('ContactStatusWidget', () {
    testWidgets('renders correctly for inactive status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: ContactStatusWidget(status: ContactStatus.inactive),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);

      expect(find.byType(Text), findsOneWidget);

      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        svgPicture.colorFilter,
        ColorFilter.mode(
          LinagoraRefColors.material().neutral[60]!,
          BlendMode.srcIn,
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, LinagoraRefColors.material().neutral[60]);
      expect(
        text.style?.fontSize,
        Theme.of(
          tester.element(find.byType(ContactStatusWidget)),
        ).textTheme.bodySmall?.fontSize,
      );
    });

    testWidgets('renders correctly for active status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: ContactStatusWidget(status: ContactStatus.active),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsNothing);
      expect(find.byType(Text), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
