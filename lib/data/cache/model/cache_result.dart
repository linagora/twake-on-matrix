// lib/data/cache/model/cache_result.dart
import 'dart:typed_data';
import 'cache_metadata.dart';

enum CacheSource { memory, disk, network }

class CacheResult {
  final Uint8List? bytes;
  final CacheSource? source;
  final CacheMetadata? metadata;

  const CacheResult._({this.bytes, this.source, this.metadata});

  factory CacheResult.hit({
    required Uint8List bytes,
    required CacheSource source,
    CacheMetadata? metadata,
  }) {
    return CacheResult._(bytes: bytes, source: source, metadata: metadata);
  }

  factory CacheResult.miss() => const CacheResult._();

  bool get isHit => bytes != null;
  bool get isMiss => bytes == null;
  bool get isFromMemory => source == CacheSource.memory;
  bool get isFromDisk => source == CacheSource.disk;
}
