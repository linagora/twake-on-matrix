enum ChunkFederationContactErrorEnum {
  chunkError;

  String get message {
    switch (this) {
      case ChunkFederationContactErrorEnum.chunkError:
        return 'Error fetching chunk federation contacts';
    }
  }
}
