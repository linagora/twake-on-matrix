import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';
import 'package:twake_chat/domain/drive/policy/drive_pick_plan_policy.dart';

DrivePickedFile _file(
  String name, {
  String? share,
  String? download,
  String? mime,
}) => DrivePickedFile(
  id: name,
  name: name,
  size: 1,
  mimeType: mime,
  shareUri: share == null ? null : Uri.parse(share),
  downloadUri: download == null ? null : Uri.parse(download),
);

void main() {
  const policy = DrivePickPlanPolicy(requireHttps: true);

  group('DrivePickPlanPolicy.plan', () {
    test('files with a sharing link are a link pick', () {
      final plan = policy.plan([
        _file('a', share: 'https://x.example/s/1'),
        _file('b', share: 'https://x.example/s/2'),
      ]);

      expect(plan.links.map((f) => f.name), ['a', 'b']);
      expect(plan.downloads, isEmpty);
    });

    test('files with only a download link are an attach pick', () {
      final plan = policy.plan([
        _file('a.pdf', download: 'https://x.example/d/1'),
        _file('b.png', download: 'https://x.example/d/2'),
      ]);

      expect(plan.downloads.map((f) => f.name), ['a.pdf', 'b.png']);
      expect(plan.links, isEmpty);
    });

    test('a pick is never both: sharing links win over download links', () {
      final plan = policy.plan([
        _file(
          'a',
          share: 'https://x.example/s/1',
          download: 'https://x.example/d/1',
        ),
      ]);

      expect(plan.links, hasLength(1));
      expect(plan.downloads, isEmpty);
    });

    test('a shortcut is never attached, by mime type or by .url name', () {
      final plan = policy.plan([
        _file('a.pdf', download: 'https://x.example/d/1'),
        _file(
          'link',
          download: 'https://x.example/d/2',
          mime: 'application/internet-shortcut',
        ),
        _file('Other.URL', download: 'https://x.example/d/3'),
      ]);

      expect(plan.downloads.map((f) => f.name), ['a.pdf']);
      expect(plan.skippedShortcuts, 2);
    });

    test('only shortcuts leaves nothing to attach and counts them', () {
      final plan = policy.plan([
        _file('a.url', download: 'https://x.example/d/1'),
      ]);

      expect(plan.downloads, isEmpty);
      expect(plan.skippedShortcuts, 1);
    });

    test('a file with no usable download link is ignored', () {
      final plan = policy.plan([
        _file('a'),
        _file('b', download: 'http://x.example/d/2'),
        _file('c', download: 'https://x.example/d/3'),
      ]);

      expect(plan.downloads.map((f) => f.name), ['c']);
    });

    test('http downloads are kept when https is not required (debug)', () {
      const debug = DrivePickPlanPolicy(requireHttps: false);

      final plan = debug.plan([_file('a', download: 'http://x.example/d/1')]);

      expect(plan.downloads, hasLength(1));
    });

    test('an empty pick has no links or downloads', () {
      final plan = policy.plan(const []);
      expect(plan.links, isEmpty);
      expect(plan.downloads, isEmpty);
    });
  });
}
