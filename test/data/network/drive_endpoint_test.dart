import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/network/drive_endpoint.dart';
import 'package:twake_chat/data/network/service_path.dart';

final _path = ServicePath('/custom/endpoint');

void _appendsThePathToThePlatformUrl() {
  final url = _path.resolveOn(Uri.parse('https://workplace.example'));

  expect(url.toString(), 'https://workplace.example/custom/endpoint');
}

void _keepsThePlatformPathPrefixAndMergesTheQuery() {
  final url = _path.resolveOn(
    Uri.parse('https://workplace.example/tenant?x=1'),
    queryParameters: {'y': '2'},
  );

  expect(
    url.toString(),
    'https://workplace.example/tenant/custom/endpoint?x=1&y=2',
  );
}

void main() {
  test('appends the path to the platform url', _appendsThePathToThePlatformUrl);
  test(
    'keeps the platform path prefix and merges the query',
    _keepsThePlatformPathPrefixAndMergesTheQuery,
  );
}
