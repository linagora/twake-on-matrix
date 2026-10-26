import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/policy/account_policy.dart';

const _policy = AccountPolicy();

void main() {
  group('nextActiveAfterRemoving', () {
    test('picks the account that followed the removed one', () {
      expect(
        _policy.nextActiveAfterRemoving(ids: ['a', 'b', 'c'], removedId: 'a'),
        'b',
      );
      expect(
        _policy.nextActiveAfterRemoving(ids: ['a', 'b', 'c'], removedId: 'b'),
        'c',
      );
    });

    test(
      'falls back to the previous account when the removed one was last',
      () {
        expect(
          _policy.nextActiveAfterRemoving(ids: ['a', 'b', 'c'], removedId: 'c'),
          'b',
        );
        expect(
          _policy.nextActiveAfterRemoving(ids: ['a', 'b'], removedId: 'b'),
          'a',
        );
      },
    );

    test('returns null when nothing remains', () {
      expect(
        _policy.nextActiveAfterRemoving(ids: ['a'], removedId: 'a'),
        isNull,
      );
    });

    test('returns null when the removed id is not in the list', () {
      expect(
        _policy.nextActiveAfterRemoving(ids: ['a', 'b'], removedId: 'x'),
        isNull,
      );
    });
  });

  group('selectInitialActive', () {
    test('keeps the persisted id when it is logged in', () {
      expect(
        _policy.selectInitialActive(loggedInIds: ['a', 'b'], persistedId: 'b'),
        'b',
      );
    });

    test('falls back to the first logged-in id when nothing is persisted', () {
      expect(
        _policy.selectInitialActive(loggedInIds: ['a', 'b'], persistedId: null),
        'a',
      );
    });

    test(
      'falls back to the first logged-in id when the persisted is unknown',
      () {
        expect(
          _policy.selectInitialActive(
            loggedInIds: ['a', 'b'],
            persistedId: 'x',
          ),
          'a',
        );
      },
    );
  });
}
