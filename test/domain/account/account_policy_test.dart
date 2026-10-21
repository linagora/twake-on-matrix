import 'package:twake_chat/domain/account/policy/account_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountPolicy.nextActiveAfterRemoving', () {
    test('picks the account that followed the removed one', () {
      expect(
        AccountPolicy.nextActiveAfterRemoving(
          ids: ['a', 'b', 'c'],
          removedId: 'a',
        ),
        'b',
      );
      expect(
        AccountPolicy.nextActiveAfterRemoving(
          ids: ['a', 'b', 'c'],
          removedId: 'b',
        ),
        'c',
      );
    });

    test(
      'falls back to the previous account when the removed one was last',
      () {
        expect(
          AccountPolicy.nextActiveAfterRemoving(
            ids: ['a', 'b', 'c'],
            removedId: 'c',
          ),
          'b',
        );
        expect(
          AccountPolicy.nextActiveAfterRemoving(
            ids: ['a', 'b'],
            removedId: 'b',
          ),
          'a',
        );
      },
    );

    test('returns null when nothing remains', () {
      expect(
        AccountPolicy.nextActiveAfterRemoving(ids: ['a'], removedId: 'a'),
        isNull,
      );
    });

    test('returns null when the removed id is not in the list', () {
      expect(
        AccountPolicy.nextActiveAfterRemoving(ids: ['a', 'b'], removedId: 'x'),
        isNull,
      );
    });
  });

  group('AccountPolicy.selectInitialActive', () {
    test('keeps the persisted id when it is logged in', () {
      expect(
        AccountPolicy.selectInitialActive(
          loggedInIds: ['a', 'b'],
          persistedId: 'b',
        ),
        'b',
      );
    });

    test('falls back to the first logged-in id when nothing is persisted', () {
      expect(
        AccountPolicy.selectInitialActive(
          loggedInIds: ['a', 'b'],
          persistedId: null,
        ),
        'a',
      );
    });

    test(
      'falls back to the first logged-in id when the persisted is unknown',
      () {
        expect(
          AccountPolicy.selectInitialActive(
            loggedInIds: ['a', 'b'],
            persistedId: 'x',
          ),
          'a',
        );
      },
    );

    test('returns null when no account is logged in', () {
      expect(
        AccountPolicy.selectInitialActive(loggedInIds: [], persistedId: 'a'),
        isNull,
      );
    });
  });
}
