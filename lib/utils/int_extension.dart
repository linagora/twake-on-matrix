import 'dart:math';

extension IntExtension on int {
  String formatBytes() {
    if (this <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(this) / log(1024)).floor();
    return '${(this / pow(1024, i)).toStringAsFixed(0)}${suffixes[i]}';
  }
}
