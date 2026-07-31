enum RetryUploadResult {
  /// The upload has been queued again
  started,

  /// A retry is already running
  alreadyInProgress,

  /// The upload is not in a failed state, there is nothing to retry
  notFailed,

  /// The file data is gone
  fileDataUnavailable,
}
