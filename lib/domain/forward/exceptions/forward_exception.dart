sealed class ForwardException implements Exception {
  const ForwardException();
}

class ForwardEmptyContentException extends ForwardException {
  const ForwardEmptyContentException();
}
