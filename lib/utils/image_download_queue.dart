import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Limits the number of concurrent image download/decode operations
/// to prevent memory spikes that cause iOS OOM kills.
///
/// Each [MxcImage] acquires a slot before starting its load and
/// releases it when done (or when disposed). If all slots are taken,
/// the request is queued and processed in FIFO order.
class ImageDownloadQueue {
  static ImageDownloadQueue _instance = ImageDownloadQueue._internal();
  static ImageDownloadQueue get instance => _instance;

  @visibleForTesting
  static set instance(ImageDownloadQueue queue) => _instance = queue;

  @visibleForTesting
  static void resetInstance() {
    _instance = ImageDownloadQueue._internal();
  }

  ImageDownloadQueue._internal({this.maxConcurrent = 4}) {
    if (maxConcurrent < 1) {
      throw ArgumentError.value(
        maxConcurrent,
        'maxConcurrent',
        'Must be greater than 0',
      );
    }
  }

  @visibleForTesting
  factory ImageDownloadQueue.forTesting({int maxConcurrent = 4}) =>
      ImageDownloadQueue._internal(maxConcurrent: maxConcurrent);

  /// Maximum number of image loads running simultaneously.
  /// 4 is a good balance: enough parallelism for fast scrolling,
  /// low enough to avoid memory pressure on iOS.
  final int maxConcurrent;

  int _running = 0;
  final Queue<_QueueEntry> _queue = Queue<_QueueEntry>();

  /// Acquires a slot in the download queue.
  ///
  /// Returns an [ImageDownloadTicket] whose [ready] future completes
  /// with `true` when a slot is available, or `false` if cancelled.
  ///
  /// The ticket must be released via [release] when work is finished,
  /// or cancelled via [ImageDownloadTicket.cancel] if no longer needed.
  ImageDownloadTicket acquire() {
    final ticket = ImageDownloadTicket._();

    if (_running < maxConcurrent) {
      _running++;
      ticket._granted = true;
      ticket._completer.complete(true);
    } else {
      final entry = _QueueEntry(ticket);
      _queue.add(entry);
      // Entry held in queue; ticket uses cancel() to skip when drained.
    }

    return ticket;
  }

  /// Releases a slot, allowing the next queued request to proceed.
  void release(ImageDownloadTicket ticket) {
    if (!ticket._granted) {
      // Was still queued — mark as cancelled and let _drainQueue skip it.
      // This is O(1) instead of O(n) queue.remove().
      ticket.cancel();
      return;
    }

    ticket._granted = false;
    _running--;

    _drainQueue();
  }

  void _drainQueue() {
    while (_running < maxConcurrent && _queue.isNotEmpty) {
      final next = _queue.removeFirst();
      if (next.ticket._cancelled) {
        if (!next.ticket._completer.isCompleted) {
          next.ticket._completer.complete(false);
        }
        continue;
      }
      _running++;
      next.ticket._granted = true;
      // Ticket granted; no longer in queue.
      if (!next.ticket._completer.isCompleted) {
        next.ticket._completer.complete(true);
      }
    }
  }

  /// Current number of active downloads (for debugging/testing).
  int get activeCount => _running;

  /// Current number of queued downloads (for debugging/testing).
  /// Note: may include cancelled entries not yet drained.
  int get queuedCount => _queue.length;
}

/// A ticket representing a pending or active slot in the download queue.
class ImageDownloadTicket {
  ImageDownloadTicket._();

  final Completer<bool> _completer = Completer<bool>();
  bool _granted = false;
  bool _cancelled = false;

  /// Resolves to `true` when a slot is available and work should start,
  /// or `false` if the ticket was cancelled before being granted.
  Future<bool> get ready => _completer.future;

  /// Whether this ticket currently holds an active slot.
  bool get isActive => _granted;

  /// Cancel this ticket. If still queued, it will be skipped by drainQueue.
  /// If already active, call [ImageDownloadQueue.release] instead.
  void cancel() {
    _cancelled = true;
    if (!_granted && !_completer.isCompleted) {
      _completer.complete(false);
    }
  }
}

class _QueueEntry {
  final ImageDownloadTicket ticket;
  const _QueueEntry(this.ticket);
}
