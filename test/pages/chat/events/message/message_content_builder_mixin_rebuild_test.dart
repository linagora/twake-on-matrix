import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/message/message_content_builder_mixin.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../../../fake_client.dart';

class _BubbleSizer with MessageContentBuilderMixin {}

/// Measures a text bubble like `MessageContentBuilder` does and counts builds.
class _MeasuredBubble extends StatelessWidget {
  const _MeasuredBubble({required this.event, required this.onBuild});

  final Event event;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    _BubbleSizer().getSizeMessageBubbleWidth(
      context,
      event: event,
      maxWidth: 300,
    );
    return const SizedBox();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Event textEvent;
  setUpAll(() async {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
    final client = await getClient();
    textEvent = Event(
      content: {'body': 'Hello from the timeline', 'msgtype': 'm.text'},
      type: 'm.room.message',
      eventId: '\$text:example.org',
      senderId: '@example:example.org',
      originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
      room: Room(id: '!room:example.abc', client: client),
    );
  });

  Future<ValueNotifier<MediaQueryData>> pumpBubble(
    WidgetTester tester,
    VoidCallback onBuild,
  ) async {
    final mediaQuery = ValueNotifier(const MediaQueryData());
    addTearDown(mediaQuery.dispose);
    await tester.pumpWidget(
      Builder(
        builder: (context) => MaterialApp(
          theme: TwakeThemes.buildTheme(context, Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: ValueListenableBuilder<MediaQueryData>(
            valueListenable: mediaQuery,
            builder: (context, data, child) =>
                MediaQuery(data: data, child: child!),
            child: _MeasuredBubble(event: textEvent, onBuild: onBuild),
          ),
        ),
      ),
    );
    return mediaQuery;
  }

  testWidgets('A keyboard inset change does not rebuild a measured bubble', (
    tester,
  ) async {
    var builds = 0;
    final mediaQuery = await pumpBubble(tester, () => builds++);
    expect(builds, 1);

    mediaQuery.value = mediaQuery.value.copyWith(
      viewInsets: const EdgeInsets.only(bottom: 300),
    );
    await tester.pump();

    expect(builds, 1);
  });

  testWidgets('A text scale change rebuilds a measured bubble', (tester) async {
    var builds = 0;
    final mediaQuery = await pumpBubble(tester, () => builds++);
    expect(builds, 1);

    mediaQuery.value = mediaQuery.value.copyWith(
      textScaler: const TextScaler.linear(1.5),
    );
    await tester.pump();

    expect(builds, 2);
  });
}
