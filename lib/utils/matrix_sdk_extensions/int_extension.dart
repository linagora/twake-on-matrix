extension IntExtension on int {
  String bytesToMB({int? placeDecimal}) {
    return (this / (1024 * 1024)).toStringAsFixed(placeDecimal ?? 0);
  }

  String bytesToKB({int? placeDecimal}) {
    return (this / 1024).toStringAsFixed(placeDecimal ?? 0);
  }

  static const oneKB = 1024 * 1024;
}
