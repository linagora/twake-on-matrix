import 'dart:math';

/// The key that ties the files of one send together, shared with the Twake web
/// client (`docs/adr/0038-media-album-batch-key.md`). The value is a UUID
/// string, the same on every file of one confirmed send. Display grouping
/// reads it; sending and forwarding write it.
///
/// Spec basis (Matrix client-server API v1.19). The spec has no notion of a
/// send; each file is an independent event, and the key is ours:
/// - the key follows the namespaced identifier grammar (reverse domain):
///   https://spec.matrix.org/v1.19/appendices/#common-namespaced-identifier-grammar
/// - a reply is a relation of one event to another, and nothing forbids putting
///   it on the first file only (mobile used to put it on the last):
///   https://spec.matrix.org/v1.19/client-server-api/#rich-replies
/// - in an encrypted room this key is inside the encrypted payload (the
///   relation of a reply is not):
///   https://spec.matrix.org/v1.19/client-server-api/#end-to-end-encryption
class MediaBatchStamp {
  const MediaBatchStamp();

  static const String contentKey = 'app.twake.chat.batch';

  /// Below this many files a send is not an album and carries no key.
  static const int minFilesForBatch = 2;

  static const String _imageMsgType = 'm.image';

  /// A fresh batch id for a send of [fileCount] files, or null for a single file.
  String? newBatchIdFor(int fileCount, {Random? random}) {
    if (fileCount < minFilesForBatch) return null;
    return _uuidV4(random ?? Random.secure());
  }

  /// The content to add to each file of a send, or null without a batch.
  Map<String, Object>? contentFor(String? batchId) {
    if (batchId == null || batchId.isEmpty) return null;
    return {contentKey: batchId};
  }

  /// [content] without the batch key: a forwarded copy never keeps the id of
  /// the original send, or forwarding one album twice into a room would merge
  /// both copies into one album.
  Map<String, Object?> withoutBatch(Map<String, Object?> content) {
    return Map<String, Object?>.from(content)..remove(contentKey);
  }

  /// [contents] of forwarded messages, with one fresh batch id on the images
  /// when two or more images go together. Other messages are left alone.
  List<Map<String, Object?>> restampForwarded(
    List<Map<String, Object?>> contents, {
    Random? random,
  }) {
    final imageCount = contents
        .where((content) => content['msgtype'] == _imageMsgType)
        .length;
    final batchId = newBatchIdFor(imageCount, random: random);
    if (batchId == null) return contents;
    return [
      for (final content in contents)
        content['msgtype'] == _imageMsgType
            ? {...content, contentKey: batchId}
            : content,
    ];
  }

  String _uuidV4(Random random) {
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
