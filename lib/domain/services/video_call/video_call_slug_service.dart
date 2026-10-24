import 'dart:math';

class VideoCallSlugService {
  VideoCallSlugService({Random? random}) : _random = random ?? Random.secure();

  static final RegExp pattern = RegExp(r'^[a-z]{3}-[a-z]{4}-[a-z]{3}$');

  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz';

  final Random _random;

  String generate() => '${_letters(3)}-${_letters(4)}-${_letters(3)}';

  /// The slug ending [roomUrl], or null when it has none.
  String? parse(String roomUrl) {
    final segments = Uri.tryParse(roomUrl)?.pathSegments ?? const [];
    final slug = segments.lastWhere(
      (segment) => segment.isNotEmpty,
      orElse: () => '',
    );
    return pattern.hasMatch(slug) ? slug : null;
  }

  String _letters(int length) => List.generate(
    length,
    (_) => _alphabet[_random.nextInt(_alphabet.length)],
  ).join();
}
