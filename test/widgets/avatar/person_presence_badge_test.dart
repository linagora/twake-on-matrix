import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';
import 'package:twake_chat/widgets/avatar/person_presence_badge.dart';

const _alice = '@alice:server';
const _dotKey = ValueKey('linagora-presence-dot');

void main() {
  late StreamController<PersonPresence?> presence;
  late int serverReads;

  setUp(() {
    presence = StreamController<PersonPresence?>();
    serverReads = 0;
  });

  tearDown(() => presence.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [
            syncedPersonPresenceProvider(
              _alice,
            ).overrideWith((ref) => presence.stream),
            personPresenceProvider(_alice).overrideWith((ref) {
              serverReads++;
              return const Stream.empty();
            }),
          ],
        ),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: PersonPresenceBadge(
              userId: _alice,
              size: 48,
              child: SizedBox.square(dimension: 48),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Color? dotColor(WidgetTester tester) {
    final dot = tester.widget<AnimatedContainer>(find.byKey(_dotKey));
    return (dot.decoration as BoxDecoration?)?.color;
  }

  testWidgets('shows no dot before the presence comes', (tester) async {
    await pump(tester);

    expect(find.byKey(_dotKey), findsNothing);
  });

  testWidgets('follows the person from online to away to offline', (
    tester,
  ) async {
    final tokens = LinagoraPresenceBadgeStyle.material();
    await pump(tester);

    presence.add(const PersonPresence(status: PresenceStatus.online));
    await tester.pumpAndSettle();
    expect(dotColor(tester), tokens.onlineColor);

    presence.add(const PersonPresence(status: PresenceStatus.away));
    await tester.pumpAndSettle();
    expect(dotColor(tester), tokens.awayColor);

    presence.add(const PersonPresence(status: PresenceStatus.offline));
    await tester.pumpAndSettle();
    expect(find.byKey(_dotKey), findsNothing);
  });

  testWidgets('never asks the server', (tester) async {
    await pump(tester);

    expect(serverReads, 0);
  });
}
