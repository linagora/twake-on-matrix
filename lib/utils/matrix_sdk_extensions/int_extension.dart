extension IntExtension on int {
  String bytesToMB({int? placeDecimal}) {
    return (this / (1024 * 1024)).toStringAsFixed(placeDecimal ?? 0);
  }

  String bytesToKB({int? placeDecimal}) {
    return (this / 1024).toStringAsFixed(placeDecimal ?? 0);
  }

  int bytesToMBInt() {
    return this ~/ (1024 * 1024);
  }

  static const oneKB = 1024 * 1024;

  String formatNumberAudioDuration() {
    String numberStr = toString();
    if (this < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }
}
