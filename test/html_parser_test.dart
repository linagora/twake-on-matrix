import 'package:fluffychat/utils/html/html_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HTML parser test", () {
    test("Content is empty", () {
      const String event = '';
      const String expected = '';
      final getContentHasPill = TwakeHtmlParser.getContentHasPill(event);
      final contentHasPill = TwakeHtmlParser.isContentHasPill(event);

      expect(contentHasPill, false);
      expect(getContentHasPill, expected);
    });

    test("Content has pill", () {
      const String event =
          'DCMMMM <a href="https://matrix.to/#/@dmm:tom-dev.xyz">@[R2D2ndndndndndndjsksjsjdjskskskkđ]</a>';

      const String expected = 'DCMMMM @dmm';

      final getContentHasPill = TwakeHtmlParser.getContentHasPill(event);
      final contentHasPill = TwakeHtmlParser.isContentHasPill(event);

      expect(getContentHasPill, expected);

      expect(contentHasPill, true);
    });

    test("Content has multi pill", () {
      const String event =
          'alo lan 1 <a href="https://matrix.to/#/@r2d2:tom-dev.xyz">@[R2D2ndndndndndndjsksjsjdjskskskkđ]</a> b <a href="https://matrix.to/#/@aloalo:tom-dev.xyz">@[R2D2ndndndndndndjsksjsjdjskskskkđ]</a> example <a href="https://matrix.to/#/@example:tom-dev.xyz">@[R2D2ndndndndndndjsksjsjdjskskskkđ]</a>';

      const String expected = 'alo lan 1 @r2d2 b @aloalo example @example';

      final getContentHasPill = TwakeHtmlParser.getContentHasPill(event);

      final contentHasPill = TwakeHtmlParser.isContentHasPill(event);

      expect(getContentHasPill, expected);
      expect(contentHasPill, true);
    });

    test("Content is not the <a> tag", () {
      const String event =
          'DCMMMM <ol start="10"><li>fox</li><li>floof</li><li>tail<br>floof</li><li>pawsies<ol><li>cute</li><li>adorable</li></ol></li></ol>';

      const String expected =
          'DCMMMM <ol start="10"><li>fox</li><li>floof</li><li>tail<br>floof</li><li>pawsies<ol><li>cute</li><li>adorable</li></ol></li></ol>';

      final getContentHasPill = TwakeHtmlParser.getContentHasPill(event);

      final contentHasPill = TwakeHtmlParser.isContentHasPill(event);

      expect(getContentHasPill, expected);
      expect(contentHasPill, false);
    });

    test("Content has pill and link", () {
      const String event =
          'VIA LINK https://github.com/linagora  <a href="https://matrix.to/#/@r2d2:tom-dev.xyz">@[R2D2ndndndndndndjsksjsjdjskskskkđ]</a>';

      const String expected = 'VIA LINK https://github.com/linagora  @r2d2';

      final getContentHasPill = TwakeHtmlParser.getContentHasPill(event);

      final contentHasPill = TwakeHtmlParser.isContentHasPill(event);

      expect(getContentHasPill, expected);
      expect(contentHasPill, true);
    });
  });
}
