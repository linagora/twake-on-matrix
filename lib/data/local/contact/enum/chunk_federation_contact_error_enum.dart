enum ChunkLookUpContactErrorEnum {
  chunkError;

  String get message {
    switch (this) {
      case ChunkLookUpContactErrorEnum.chunkError:
        return 'Error fetching chunk federation contacts';
    }
  }
}
