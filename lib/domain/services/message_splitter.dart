import 'package:characters/characters.dart';

/// Splits a text into parts of at most [maxLength] UTF-16 code units, cutting
/// only between grapheme clusters so an emoji is never broken. A grapheme
/// longer than [maxLength] stays whole in its own part.
final class MessageSplitter {
  const MessageSplitter({required this.maxLength})
    : assert(maxLength > 0, 'maxLength must be positive');

  final int maxLength;

  List<String> split(String text) {
    if (text.length <= maxLength) return [text];

    final List<String> parts = [];
    final StringBuffer currentPart = StringBuffer();
    for (final String grapheme in text.characters) {
      final bool isPartFull = currentPart.length + grapheme.length > maxLength;
      if (isPartFull && currentPart.isNotEmpty) {
        parts.add(currentPart.toString());
        currentPart.clear();
      }
      currentPart.write(grapheme);
    }
    if (currentPart.isNotEmpty) parts.add(currentPart.toString());
    return parts;
  }
}
