// lib/data/cache/model/cache_metadata.dart

class CacheMetadata {
  final String? etag;
  final String? lastModified;
  final int? width;
  final int? height;
  final bool isThumbnail;
  final DateTime createdAt;

  const CacheMetadata({
    this.etag,
    this.lastModified,
    this.width,
    this.height,
    this.isThumbnail = false,
    required this.createdAt,
  });

  factory CacheMetadata.fromMap(Map<String, dynamic> map) {
    return CacheMetadata(
      etag: map['etag'] as String?,
      lastModified: map['last_modified'] as String?,
      width: map['width'] as int?,
      height: map['height'] as int?,
      isThumbnail: (map['is_thumbnail'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() => {
    'etag': etag,
    'last_modified': lastModified,
    'width': width,
    'height': height,
    'is_thumbnail': isThumbnail ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  bool get hasValidationHeaders => etag != null || lastModified != null;
}
