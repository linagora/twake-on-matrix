import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';

/// Turns the links the user picked into the text of one message: a Markdown
/// link per line, as the web app does. The Matrix SDK turns it into
/// `formatted_body` when the message is sent.
class DriveLinksMessagePolicy {
  const DriveLinksMessagePolicy({required this.requireHttps});

  /// Release builds only send https links.
  final bool requireHttps;

  /// The message text, or an empty string when no picked file has a link that
  /// is safe to send.
  String format(List<DrivePickedFile> files) =>
      files.map(_lineOf).whereType<String>().join('\n');

  /// The most characters of one message: the Matrix text splitter cuts at any
  /// character above 4096, and a link cut in two is broken in both halves.
  static const maxMessageLength = 4000;

  /// [text] as messages of at most [maxLength] characters, cut between lines
  /// so no link is split. A single line longer than the limit stays whole.
  List<String> split(String text, {int maxLength = maxMessageLength}) {
    final messages = <String>[];
    final current = StringBuffer();
    for (final line in text.split('\n')) {
      final extra = current.isEmpty ? line.length : line.length + 1;
      if (current.isNotEmpty && current.length + extra > maxLength) {
        messages.add(current.toString());
        current.clear();
      }
      if (current.isNotEmpty) current.write('\n');
      current.write(line);
    }
    if (current.isNotEmpty) messages.add(current.toString());
    return messages;
  }

  String? _lineOf(DrivePickedFile file) {
    final uri = file.shareUri;
    if (uri == null || !_isSafe(uri)) return null;
    // A bracket would end the label early, and a backslash would escape the
    // closing one: Markdown here has no escape, so they are dropped. A line
    // break would put the label and the URL on two lines, which `split` could
    // then send apart.
    final label = file.name
        .replaceAll(RegExp(r'[\[\]\\]'), '')
        .replaceAll(RegExp(r'\s*[\r\n]+\s*'), ' ');
    // A parenthesis would end the URL early.
    final url = uri.toString().replaceAll('(', '%28').replaceAll(')', '%29');
    return _fitted(label, url);
  }

  /// The link as one line within [maxMessageLength]: the label gives way, and
  /// a link whose URL alone is too long is left out, as the text sender would
  /// cut it in two.
  String? _fitted(String label, String url) {
    final room = maxMessageLength - url.length - '[]()'.length;
    if (room < 1) return null;
    final fitted = _cut(label, room);
    return '[$fitted]($url)';
  }

  /// [text] cut to at most [length] UTF-16 units, never inside a pair.
  String _cut(String text, int length) {
    final kept = <int>[];
    var used = 0;
    for (final rune in text.runes) {
      used += rune > 0xFFFF ? 2 : 1;
      if (used > length) break;
      kept.add(rune);
    }
    return String.fromCharCodes(kept);
  }

  bool _isSafe(Uri uri) =>
      uri.hasAuthority &&
      (uri.isScheme('https') || (!requireHttps && uri.isScheme('http')));
}
