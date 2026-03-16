# 35. UI Performance Optimizations

Date: 2026-03-12

## Status

Accepted

## Context

A general audit of the application's runtime behaviour revealed unnecessary work on the main isolate, excessive memory consumption, resource leaks, and redundant widget rebuilds. These issues existed across the whole app — chat views, media handling, settings screens, stories — and were not limited to a single user flow.

Seven categories of problems were identified:

1. **Cascading rebuilds** — Unfiltered event streams, empty `setState(() {})` calls, and missing `.distinct()` operators caused widgets to rebuild when nothing visible had changed.
2. **Stream subscription leaks** — Several stream subscriptions were never cancelled on dispose, keeping listeners alive after their widget was gone.
3. **Heavy synchronous operations on the main isolate** — Synchronous file I/O (`readAsBytesSync`, `writeAsBytesSync`) and large JSON decoding blocked the UI thread.
4. **Oversized image decoding** — Flutter decoded images at their full native resolution regardless of display size. A 1920×1445 thumbnail shown at 60×60 consumed ~14 MB of RAM and blocked the main thread during decode.
5. **No size-bounded image cache** — The in-memory image cache was a simple FIFO with a fixed entry count, no size budget, and no LRU (Least Recently Used) promotion — causing redundant downloads and unbounded memory growth.
6. **Missing RepaintBoundary** — Image-heavy widgets were re-rasterized on every parent repaint.
7. **Expensive per-frame work in the scroll pipeline** — The viewport notifier iterated all registered message contexts on every scroll tick, mark-as-read did linear scans, link previews fired HTTP requests eagerly, and timeline updates triggered full rebuilds mid-gesture.

## Decision

### 1. Stream and rebuild hygiene

**Filtered event stream** — The `onEvent.stream` listener in the chat controller now filters with `.where((e) => e.roomID == room?.id)` so events from other rooms are discarded before reaching the listener.

**Distinct sync status** — `ConnectionStatusHeader` uses `.map((s) => s.status).distinct()` instead of rebuilding on every sync progress update.

**Presence stream filter** — Added `.where((sync) => sync.presence?.isNotEmpty ?? false)` to skip syncs with no presence data.

**setState audit** — Fixed 38 empty `setState(() {})` calls across 19 files: state mutations moved inside the callback, redundant calls removed, remaining ones documented.

### 2. Subscription lifecycle

**onToDeviceEvent / onUiaRequest** — Stored subscriptions in `matrix.dart` with a `??=` guard and cancel them in both `_cancelSubs()` and `dispose()`.

**Timestamp timer** — Added `_timestampTimer?.cancel()` in `dispose()` and a `mounted` guard in `_handleHideStickyTimestamp()` to prevent `ValueNotifier`-after-dispose errors.

**Link preview subscription** — `GetPreviewUrlMixin` now stores its stream subscription and exposes `disposeGetPreviewUrlMixin()` to cancel it and dispose the `ValueNotifier`. Both consumers call it in `dispose()`.

### 3. Main-thread offloading

**Async file I/O** — Replaced `readAsBytesSync()` and `writeAsBytesSync()` with their async counterparts in draft input and download-for-preview flows.

**Persistent isolate** — Created `FileIOWorker` with a long-lived background isolate (spawned once via `Isolate.spawn`, reused for all file writes), avoiding the per-call overhead of `compute()`. Includes a web fallback via `kIsWeb`.

**JSON decode offload** — Moved `jsonDecode(export)` in `HiveCollectionsDatabase` to `compute()` with a top-level function so large database exports don't block the UI.

### 4. Image decode sizing

Added `cacheWidth` / `cacheHeight` on 8 `Image` widgets that were missing them: file tile thumbnails, sending video thumbnails, video player thumbnails, wallpaper previews (settings + chat background + invitation), story view, and story creation background. Flutter now decodes at display size × `devicePixelRatio` instead of native resolution. For `DecorationImage` with `MemoryImage`, wrapped in `ResizeImage`.

Full-screen viewers with pinch-zoom (`ImageViewer`) are left at full resolution intentionally.

### 5. In-memory image cache (MxcImageCacheManager)

Replaced the FIFO 100-entry cache with an LRU cache: 300 entries max, 50 MB size budget. `getImage()` promotes entries to most-recently-used. Eviction removes the least-recently-used entry when either limit is exceeded. Added `clear()`, `currentSizeBytes`, and `length` for observability and testing.

### 6. RepaintBoundary

Wrapped the `build()` output of `MxcImage` in a `RepaintBoundary` — this single change covers all 15 usages (avatars, thumbnails, media). Also added `RepaintBoundary` around `Image.memory` / `Image.network` in `SendingVideoWidget`, `SendingImageInfoWidget`, `EventVideoPlayer`, `BaseFileTileWidget`, and `UnencryptedImageBuilderWeb`.

### 7. Scroll pipeline

**Batched InViewState notifications** — Patched the `inview_notifier_list` Linagora fork: `onScroll()` now collects all in/out changes in a single loop, then calls `notifyListeners()` once. Changed `_currentInViewIds` from `List` to `Set` for O(1) lookups.

**Cached event index map** — `AutoMarkAsReadMixin.onEventVisible()` replaced two `indexWhere()` O(n) scans with a cached `Map<String, int>`. The map rebuilds only when `timeline.events.length` changes.

**Deferred link preview fetch** — `TwakeLinkPreview.initState()` waits 150 ms before firing the HTTP request. If the widget is disposed (scrolled away) before the timer fires, no request is made.

**Gated updateView** — During active scroll, `updateView()` sets a `_hasPendingUpdateView` flag instead of calling `setState()`. The pending rebuild is flushed once in `handleScrollEndNotification()`.

## Consequences

### Benefits

- Eliminated per-frame O(n) work, mid-scroll rebuilds, and HTTP request bursts during scrolling
- Image memory usage drops by an order of magnitude for thumbnails and previews (e.g., 14 MB → ~15 KB for a 60×60 thumbnail)
- LRU cache with size budget prevents unbounded memory growth and redundant downloads
- RepaintBoundary confines rasterization to changed images only
- Async I/O and background isolate free the main thread for frame rendering
- Stream filters and subscription cleanup eliminate unnecessary listener callbacks and prevent leaks

### Trade-offs

- The 150 ms link preview delay adds a barely perceptible lag — the HTTP round-trip is orders of magnitude longer
- Deferred `updateView()` means new messages arriving during scroll appear when scrolling stops — expected UX since the user is looking at older content
- The `InViewState` patch lives in the Linagora fork of `inview_notifier_list`; upstream updates require re-applying it
- `cacheWidth`/`cacheHeight` are intentionally omitted on full-screen image viewers where pinch-zoom requires full resolution
