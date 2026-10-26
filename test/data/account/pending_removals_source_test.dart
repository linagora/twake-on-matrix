import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

void main() {
  late PendingRemovalsSource source;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    source = PendingRemovalsSource(Store());
  });

  test('reads back what was written, and deletes the key when empty', () async {
    await source.write({'a', 'b'});
    expect(await source.read(), {'a', 'b'});

    await source.write({});
    expect(await Store().getItem(PendingRemovalsSource.key), isNull);
  });

  group('a value that cannot be decoded', () {
    for (final entry in {
      'not json': 'not json',
      'not a list': '{"a": 1}',
      'not strings': '[1, 2]',
    }.entries) {
      test('${entry.key} is dropped, not thrown again at every read', () async {
        await Store().setItem(PendingRemovalsSource.key, entry.value);

        expect(await source.read(), isEmpty);
        expect(await Store().getItem(PendingRemovalsSource.key), isNull);

        await source.write({'a'});
        expect(await source.read(), {'a'});
      });
    }
  });
}
