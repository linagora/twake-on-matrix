class ServerConfig {
  ServerConfig({this.mUploadSize});

  ServerConfig.fromJson(Map<String, Object?> json)
    : mUploadSize = ((v) => v != null ? v as int : null)(json['m.upload.size']);
  Map<String, Object?> toJson() {
    final mUploadSize = this.mUploadSize;
    return {if (mUploadSize != null) 'm.upload.size': mUploadSize};
  }

  /// The maximum size an upload can be in bytes.
  /// Clients SHOULD use this as a guide when uploading content.
  /// If not listed or null, the size limit should be treated as unknown.
  int? mUploadSize;
}
