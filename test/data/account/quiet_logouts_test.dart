import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/quiet_logouts.dart';

void main() {
  late QuietLogouts quiet;

  setUp(() => quiet = QuietLogouts());

  test('a logout nobody announced is not quiet', () {
    expect(quiet.consume('a', LoginState.loggedOut), isFalse);
  });

  test('the announced logout is quiet, however late it is seen', () async {
    quiet.announce('a');

    await pumpEventQueue();

    expect(quiet.consume('a', LoginState.loggedOut), isTrue);
  });

  test('later logout states of the signed-out client are skipped too', () {
    quiet.announce('a');
    quiet.consume('a', LoginState.loggedOut);

    expect(quiet.consume('a', LoginState.softLoggedOut), isTrue);
    expect(quiet.consume('a', LoginState.loggedOut), isTrue);
  });

  test('another client keeps its logout handlers', () {
    quiet.announce('a');

    expect(quiet.consume('b', LoginState.loggedOut), isFalse);
    expect(quiet.consume('a', LoginState.loggedOut), isTrue);
  });

  test('a login ends the quiet period, also for a logout never seen', () {
    quiet.announce('a');
    expect(quiet.consume('a', LoginState.loggedIn), isFalse);
    expect(quiet.consume('a', LoginState.loggedOut), isFalse);

    quiet.announce('a');
    quiet.consume('a', LoginState.loggedOut);
    expect(quiet.consume('a', LoginState.loggedIn), isFalse);
    expect(quiet.consume('a', LoginState.loggedOut), isFalse);
  });

  test('a soft logout before the announced logout is skipped, mark kept', () {
    quiet.announce('a');

    expect(quiet.consume('a', LoginState.softLoggedOut), isTrue);

    expect(quiet.consume('a', LoginState.loggedOut), isTrue);
  });

  test(
    'a soft logout of a client that was never signed out is not skipped',
    () {
      expect(quiet.consume('a', LoginState.softLoggedOut), isFalse);
    },
  );

  test('announcing again starts a new quiet period', () {
    quiet.announce('a');
    quiet.consume('a', LoginState.loggedOut);
    quiet.consume('a', LoginState.loggedIn);

    quiet.announce('a');

    expect(quiet.consume('a', LoginState.loggedOut), isTrue);
  });

  test('forgetting a client drops its marks, announced or signed out', () {
    quiet.announce('a');
    quiet.forget('a');
    expect(quiet.consume('a', LoginState.loggedOut), isFalse);

    quiet.announce('b');
    quiet.consume('b', LoginState.loggedOut);
    quiet.forget('b');
    expect(quiet.consume('b', LoginState.softLoggedOut), isFalse);
    expect(quiet.consume('b', LoginState.loggedOut), isFalse);
  });

  group('every event from every state', () {
    const starts = <String, List<String>>{
      'nothing announced': [],
      'announced': ['announce'],
      'signed out': ['announce', 'loggedOut'],
    };
    const events = [
      'announce',
      'forget',
      'loggedIn',
      'loggedOut',
      'softLoggedOut',
    ];

    void apply(String event) {
      switch (event) {
        case 'announce':
          quiet.announce('a');
        case 'forget':
          quiet.forget('a');
        case 'loggedIn':
          quiet.consume('a', LoginState.loggedIn);
        case 'loggedOut':
          quiet.consume('a', LoginState.loggedOut);
        case 'softLoggedOut':
          quiet.consume('a', LoginState.softLoggedOut);
      }
    }

    for (final start in starts.entries) {
      for (final event in events) {
        test('${start.key}, then $event', () {
          start.value.forEach(apply);
          final wasQuiet = start.key != 'nothing announced';

          apply(event);

          if (event == 'loggedIn' || event == 'forget') {
            expect(quiet.consume('a', LoginState.loggedOut), isFalse);
            expect(quiet.consume('a', LoginState.softLoggedOut), isFalse);
          }
          if (!wasQuiet && event != 'announce') {
            expect(
              quiet.consume('a', LoginState.loggedOut),
              isFalse,
              reason: 'nothing was announced, so no logout is quiet',
            );
          }
          if (event == 'announce') {
            expect(quiet.consume('a', LoginState.loggedOut), isTrue);
          }
        });
      }
    }
  });
}
