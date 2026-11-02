sealed class FolderException implements Exception {
  const FolderException();
}

class FolderNameRequiredException extends FolderException {
  const FolderNameRequiredException();
}

/// Another folder has this name, or a built-in filter has it.
class FolderNameTakenException extends FolderException {
  const FolderNameTakenException();
}

class FolderSaveFailedException extends FolderException {
  const FolderSaveFailedException();
}
