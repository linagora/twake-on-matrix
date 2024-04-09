class SaveToGalleryException implements Exception {
  final dynamic error;

  SaveToGalleryException({
    this.error,
  });

  @override
  String toString() => error;
}
