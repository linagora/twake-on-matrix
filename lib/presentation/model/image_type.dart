enum ImageType {
  heic(name: 'image/heic'),
  png(name: 'image/png'),
  jpg(name: 'image/jpg');

  const ImageType({required this.name});

  final String name;
}
