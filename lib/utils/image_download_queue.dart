import 'dart:async';
import 'dart:collection';

/// Limits the number of concurrent image download/decode operations
/// to prevent memory spikes that cause iOS OOM kills.
///
/// Each [MxcImage] acquires a slot before starting its load and
/// releases it when done (or when disposed). If all slots are taken,
/// the request is queued and processed in FIFO order.
class ImageDownloadQueue {
  static final ImageDownloadQueue _instance = ImageDownloadQueue._();
  static ImageDownloadQueue get instance => _instance;

  ImageDownloadQueue._();

  /// Maximum number of image loads running simultaneously.
  /// 4 is a good balance: enough parallelism for fast scrolling,
  /// low enough to avoid memory pressure on iOS.
  static const int maxConcurrent = 4;

  int _running = 0;
  final Queue<_QueueEntry> _queue = Queue<_QueueEntry>();

  /// Acquires a slot in the download queue.
  ///
  /// Returns a [Future] that completes when a slot is available.
  /// The returned [ImageDownloadTicket] must be released by calling
  /// [release] when the download/decode is finished or cancelled.
  ///
  /// If [cancel] is called on the ticket before the slot is acquired,
  /// the future completes with `false` (meaning: don't start the work).
  ImageDownloadTicket acquire() {
    final ticket = ImageDownloadTicket._();

    if (_running < maxConcurrent) {
      _running++;
      ticket._granted = true;
      ticket._completer.complete(true);
    } else {
      final entry = _QueueEntry(ticket);
      _queue.add(entry);
      ticket._queueEntry = entry;
    }

    return ticket;
  }

  /// Releases a slot, allowing the next queued request to proceed.
  void release(ImageDownloadTicket ticket) {
    if (!ticket._granted) {
      // Was still queued — just remove from queue
      if (ticket._queueEntry != null) {
        _queue.remove(ticket._queueEntry);
        ticket._queueEntry = null;
      }
      if (!ticket._completer.isCompleted) {
        ticket._completer.complete(false);
      }
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
        // Skip cancelled entries
        if (!next.ticket._completer.isCompleted) {
          next.ticket._completer.complete(false);
        }
        continue;
      }
      _running++;
      next.ticket._granted = true;
      next.ticket._queueEntry = null;
      if (!next.ticket._completer.isCompleted) {
        next.ticket._completer.complete(true);
      }
    }
  }

  /// Current number of active downloads (for debugging).
  int get activeCount => _running;

  /// Current number of queued downloads (for debugging).
  int get queuedCount => _queue.length;
}

/// A ticket representing a pending or active slot in the download queue.
class ImageDownloadTicket {
  ImageDownloadTicket._();

  final Completer<bool> _completer = Completer<bool>();
  bool _granted = false;
  bool _cancelled = false;
  _QueueEntry? _queueEntry;

  /// Resolves to `true` when a slot is available and work should start,
  /// or `false` if the ticket was cancelled before being granted.
  Future<bool> get ready => _completer.future;

  /// Whether this ticket currently holds an active slot.
  bool get isActive => _granted;

  /// Cancel this ticket. If still queued, it will be removed.
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
