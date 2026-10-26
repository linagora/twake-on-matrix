import 'dart:math';

class VideoCallSlugService {
  static final RegExp pattern = RegExp(r'^[a-z]{3}-[a-z]{4}-[a-z]{3}$');

  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz';

  final Random _random = Random.secure();

  String generate() => '${_letters(3)}-${_letters(4)}-${_letters(3)}';

  /// The slug of [roomUrl] when it is exactly one slug segment under
  /// [baseUrl], null otherwise.
  String? parse(String roomUrl, {required String baseUrl}) {
    final room = Uri.tryParse(roomUrl);
    final base = Uri.tryParse(baseUrl);
    if (room == null || base == null) return null;
    if (room.scheme != base.scheme ||
        room.host != base.host ||
        room.port != base.port) {
      return null;
    }
    final baseSegments = _nonEmpty(base.pathSegments);
    final roomSegments = _nonEmpty(room.pathSegments);
    if (roomSegments.length != baseSegments.length + 1) return null;
    for (var i = 0; i < baseSegments.length; i++) {
      if (roomSegments[i] != baseSegments[i]) return null;
    }
    final slug = roomSegments.last;
    return pattern.hasMatch(slug) ? slug : null;
  }

  List<String> _nonEmpty(List<String> segments) =>
      segments.where((segment) => segment.isNotEmpty).toList();

  String _letters(int length) => List.generate(
    length,
    (_) => _alphabet[_random.nextInt(_alphabet.length)],
  ).join();
}
