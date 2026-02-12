// lib/data/cache/model/cache_entry.dart
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class CacheEntry extends Equatable {
  final String contentHash;
  final String mediaType;
  final Uint8List bytes;
  final int sizeBytes;
  final int accessCount;
  final DateTime lastAccessed;
  final DateTime createdAt;

  const CacheEntry({
    required this.contentHash,
    required this.mediaType,
    required this.bytes,
    required this.sizeBytes,
    required this.accessCount,
    required this.lastAccessed,
    required this.createdAt,
  });

  factory CacheEntry.fromMap(Map<String, dynamic> map) {
    return CacheEntry(
      contentHash: map['content_hash'] as String,
      mediaType: map['media_type'] as String,
      bytes: map['blob'] as Uint8List,
      sizeBytes: map['size_bytes'] as int,
      accessCount: map['access_count'] as int,
      lastAccessed: DateTime.fromMillisecondsSinceEpoch(
        map['last_accessed'] as int,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() => {
    'content_hash': contentHash,
    'media_type': mediaType,
    'blob': bytes,
    'size_bytes': sizeBytes,
    'access_count': accessCount,
    'last_accessed': lastAccessed.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  @override
  List<Object?> get props => [
    contentHash,
    mediaType,
    bytes,
    sizeBytes,
    accessCount,
    lastAccessed,
    createdAt,
  ];
}
