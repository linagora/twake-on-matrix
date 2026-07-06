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

  static const oneKB = 1024;

  static const oneMB = 1024 * 1024;

  /// Formats a transfer-progress string, picking the unit from [total].
  ///
  /// Uses MB for files >= 1 MB and KB for smaller ones, so sub-1MB transfers
  /// still show visible progress instead of "0.00 MB / 0.00 MB". When
  /// [includeTotal] is false only the received half is returned (e.g.
  /// "12 KB / "), letting the caller render the total separately.
  static String formatTransferProgress(
    int receive,
    int total, {
    bool includeTotal = true,
  }) {
    final useMB = total >= oneMB;
    final unit = useMB ? 'MB' : 'KB';
    final decimals = useMB ? 2 : 0;
    final receiveText = useMB
        ? receive.bytesToMB(placeDecimal: decimals)
        : receive.bytesToKB(placeDecimal: decimals);
    if (!includeTotal) {
      return '$receiveText $unit / ';
    }
    final totalText = useMB
        ? total.bytesToMB(placeDecimal: decimals)
        : total.bytesToKB(placeDecimal: decimals);
    return '$receiveText $unit / $totalText $unit';
  }

  String formatNumberAudioDuration() {
    String numberStr = toString();
    if (this < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }
}
