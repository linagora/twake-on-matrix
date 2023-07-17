extension DoubleExtension on int {
  String bytesToMB() {
    return (this / (1024 * 1024)).toString();
  }
}