class FileNotExistException implements Exception {
  final String path;

  FileNotExistException({required this.path});

  @override
  String toString() => 'FileNotExistException: $path';
}
