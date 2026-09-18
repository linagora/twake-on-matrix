extension BeautifyStringExtension on String {
  String get beautified {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(substring(i, i + 1));
      if (i % 4 == 3) {
        buffer.write(' ');
      }
      if (i % 16 == 15) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }
}
