import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/search/recent_contacts_banner_widget.dart';
import 'package:twake_chat/pages/search/search.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/theme_builder.dart';

import 'recent_contacts_banner_widget_test.mocks.dart';

const _longName = 'Alexandrine-Marie Delacroix-Montgolfier';
const _shortName = 'Jo';

class _FakeSearchScreenState extends Fake implements SearchScreenState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => '';
}

MockRoom _room(String id, String name) {
  final room = MockRoom();
  when(room.id).thenReturn(id);
  when(room.avatar).thenReturn(null);
  when(room.getLocalizedDisplayname(any)).thenReturn(name);
  return room;
}

Future<void> _pumpBanner(
  WidgetTester tester,
  List<Room> rooms, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    ThemeBuilder(
      builder: (context, themeMode, primaryColor) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: LocalizationService.supportedLocales,
        theme: TwakeThemes.buildTheme(context, Brightness.light, primaryColor),
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: textScaler.scale(1),
          maxScaleFactor: textScaler.scale(1),
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PreSearchRecentContactsContainer(
                    searchController: _FakeSearchScreenState(),
                    recentRooms: rooms,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

RenderParagraph _paragraphOf(WidgetTester tester, String name) =>
    tester.renderObject<RenderParagraph>(find.text(name, findRichText: true));

double _lineHeight(RenderParagraph paragraph) =>
    paragraph.getFullHeightForCaret(const TextPosition(offset: 0));

@GenerateNiceMocks([MockSpec<Room>()])
void main() {
  setUpAll(() {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton(ResponsiveUtils());
    }
  });

  testWidgets('a long name wraps on two lines, a short name stays on one', (
    tester,
  ) async {
    await _pumpBanner(tester, [
      _room('!long:localhost', _longName),
      _room('!short:localhost', _shortName),
    ]);

    final long = _paragraphOf(tester, _longName);
    expect(long.maxLines, 2);
    expect(long.size.height, moreOrLessEquals(2 * _lineHeight(long)));

    final short = _paragraphOf(tester, _shortName);
    expect(short.size.height, moreOrLessEquals(_lineHeight(short)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('avatars stay aligned whatever the length of the names', (
    tester,
  ) async {
    await _pumpBanner(tester, [
      _room('!long:localhost', _longName),
      _room('!short:localhost', _shortName),
    ]);

    final avatars = find.byType(Avatar);
    expect(
      tester.getTopLeft(avatars.at(0)).dy,
      tester.getTopLeft(avatars.at(1)).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('two-line names do not overflow at the largest text size', (
    tester,
  ) async {
    await _pumpBanner(tester, [
      _room('!long:localhost', _longName),
      _room('!short:localhost', _shortName),
    ], textScaler: const TextScaler.linear(2));

    final long = _paragraphOf(tester, _longName);
    expect(long.size.height, moreOrLessEquals(2 * _lineHeight(long)));
    expect(tester.takeException(), isNull);
  });
}
