part of 'chat.dart';

/// Parameters for one jump-to-event attempt (generation supersedes older ones).
class ChatJumpRequest extends Equatable {
  const ChatJumpRequest({
    required this.eventId,
    required this.generation,
    required this.highlight,
    this.allowContextualReload = true,
  });

  final String eventId;
  final int generation;
  final bool highlight;

  /// When false, stay on the live timeline even if it is large.
  ///
  /// Used by unread-divider scroll (`_initUnreadLocation`): a contextual
  /// `eventContextId` reload sets `allowNewEvent=false`, which breaks
  /// `_isAtLiveBottom` / mark-as-read after the user returns to the bottom.
  final bool allowContextualReload;

  @override
  List<Object?> get props => [
    eventId,
    generation,
    highlight,
    allowContextualReload,
  ];
}

/// Seek/reveal context for a [ChatJumpRequest] at a timeline index.
class ChatJumpSeekSession {
  const ChatJumpSeekSession({
    required this.request,
    required this.targetIndex,
    required this.displayIndex,
  });

  final ChatJumpRequest request;
  final int targetIndex;
  final int displayIndex;
}

enum _SeekPageOutcome { found, stop, continueSeek }

/// Scrolls the chat timeline to a target event and optionally highlights it.
///
/// Center-anchored `_top`/`_bottom` lists break naive `scrollToIndex` /
/// `ensureVisible`: the row can be built (`GlobalObjectKey` present,
/// `tagMap` hit) while `localToGlobal` is still NaN (off-screen cache).
/// Logs showed `scrollToIndex` "succeeding" then `inViewport=false`.
///
/// Strategy:
/// 1. Load a small timeline window around the event when needed.
/// 2. Raise [ChatController.jumpListCacheExtent] so the row builds.
/// 3. If the row has a finite viewport position → center it.
/// 4. Else page the viewport toward the target index until the position
///    becomes finite (or we hit a scroll edge), then center.
/// 5. Highlight only after the row is actually in the viewport.
extension ChatScrollToEventMixin on ChatController {
  static const double _jumpMountCacheExtent = 20000;
  static const int _jumpWindowMaxEvents = 60;
  static const int _maxMountFrames = 90;
  static const int _maxSeekPages = 25;

  bool _isJumpCurrent(ChatJumpRequest request) {
    return request.generation == _scrollGeneration && mounted;
  }

  void _beginProgrammaticScroll() {
    _programmaticScrollDepth++;
    _isProgrammaticScrolling = true;
  }

  void _endProgrammaticScroll() {
    _programmaticScrollDepth = (_programmaticScrollDepth - 1).clamp(0, 1 << 30);
    if (_programmaticScrollDepth == 0) {
      _isProgrammaticScrolling = false;
      // Jump may have finished while the viewport is already at the live
      // bottom (or the user scrolled there during the jump). Re-check so
      // unread badges are not stuck until the next manual scroll event.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markLatestReadIfAtBottom();
      });
    }
  }

  int getDisplayEventIndex(int eventIndex) {
    const addedHeadItemsInChat = 1;
    return eventIndex + addedHeadItemsInChat;
  }

  /// Index matching [ChatScrollView]'s `_eventIndexMap` (timestamp desc).
  int? _visibleTimelineIndex(ChatJumpRequest request) {
    final sorted = _sortedTimelineEvents;
    if (sorted.isEmpty) return null;
    final index = sorted.indexWhere(
      (event) => event.eventId == request.eventId && event.isVisibleInGui,
    );
    return index < 0 ? null : index;
  }

  List<Event> get _sortedTimelineEvents {
    final events = timeline?.events;
    if (events == null) return const [];
    return List<Event>.from(events)
      ..sort((a, b) => b.originServerTs.compareTo(a.originServerTs));
  }

  bool _isTargetRowBuilt(ChatJumpRequest request) {
    return GlobalObjectKey(request.eventId).currentContext != null;
  }

  bool get _isChatEventListReady {
    return timeline != null &&
        openingChatViewStateNotifier.value is ViewEventListSuccess;
  }

  /// Finite [localToGlobal] dy relative to the scroll viewport.
  ///
  /// Center-list off-screen / kept-alive rows often yield NaN here even when
  /// the [GlobalObjectKey] exists (see TW-3222).
  double? _targetDyInScrollViewport(ChatJumpRequest request) {
    return _dyForEventId(request.eventId);
  }

  double? _dyForEventId(String eventId) {
    final itemContext = GlobalObjectKey(eventId).currentContext;
    if (itemContext == null || !scrollController.hasClients) return null;

    final itemBox = itemContext.findRenderObject() as RenderBox?;
    final scrollBox =
        scrollController.position.context.notificationContext
                ?.findRenderObject()
            as RenderBox?;
    if (itemBox == null || scrollBox == null) return null;

    final offset = itemBox.localToGlobal(Offset.zero, ancestor: scrollBox);
    if (!offset.dy.isFinite) return null;
    return offset.dy;
  }

  bool _isTargetInViewport(ChatJumpRequest request) {
    final dy = _targetDyInScrollViewport(request);
    if (dy == null || !scrollController.hasClients) return false;

    final itemContext = GlobalObjectKey(request.eventId).currentContext!;
    final itemBox = itemContext.findRenderObject() as RenderBox?;
    final scrollBox =
        scrollController.position.context.notificationContext
                ?.findRenderObject()
            as RenderBox?;
    if (itemBox == null || scrollBox == null) return false;

    final viewportHeight = scrollBox.size.height;
    final itemHeight = itemBox.size.height;
    return dy + itemHeight > 0 && dy < viewportHeight;
  }

  bool _isFastPathReady(ChatJumpSeekSession session) {
    return _isTargetRowBuilt(session.request) &&
        _isTargetInViewport(session.request);
  }

  /// Timeline index of any currently on-screen (finite-position) message.
  int? _findFiniteTimelineIndex() {
    final sorted = _sortedTimelineEvents;
    for (var i = 0; i < sorted.length; i++) {
      final id = sorted[i].eventId;
      if (GlobalObjectKey(id).currentContext == null) continue;
      if (_dyForEventId(id) != null) return i;
    }
    return null;
  }

  Future<void> _reloadTimelineAroundEvent(ChatJumpRequest request) async {
    timeline?.cancelSubscriptions();
    timeline = null;
    loadTimelineFuture =
        _getTimeline(
          eventContextId: request.eventId,
          commitOnlyIfJumpGeneration: request.generation,
        ).onError((e, s) {
          Logs().e(
            'Chat::scrollToEventId(): Unable to load timeline around '
            '${request.eventId}',
            e,
            s,
          );
        });
    rebuildChatForJump();
    await loadTimelineFuture;
    if (!mounted || !_isJumpCurrent(request)) return;
    // ChatEventList is gated on ViewEventListSuccess. Opening-room
    // `_tryRequestHistory` may still be Loading — force Success so rows
    // (and GlobalObjectKeys) can mount for the jump.
    _updateOpeningChatViewStateNotifier(ViewEventListSuccess());
    rebuildChatForJump();
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;
  }

  Future<void> _raiseJumpMountCacheExtent() async {
    if (jumpListCacheExtent == _jumpMountCacheExtent) return;
    jumpListCacheExtent = _jumpMountCacheExtent;
    rebuildChatForJump();
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;
  }

  void _captureJumpCacheBaselineIfNeeded() {
    // First jump in an overlapping sequence owns the pre-jump baseline
    // (including a legitimate null).
    if (_hasJumpCacheExtentBaseline) return;
    _hasJumpCacheExtentBaseline = true;
    _jumpCacheExtentBaseline = jumpListCacheExtent;
  }

  void _restoreJumpCacheBaselineIfCurrent(ChatJumpRequest request) {
    if (request.generation != _scrollGeneration) return;
    if (!_hasJumpCacheExtentBaseline) return;
    if (jumpListCacheExtent != _jumpCacheExtentBaseline) {
      jumpListCacheExtent = _jumpCacheExtentBaseline;
      rebuildChatForJump();
    }
    _jumpCacheExtentBaseline = null;
    _hasJumpCacheExtentBaseline = false;
  }

  bool _shouldLogMountWait(int frame) {
    if (_isChatEventListReady) return false;
    return frame % 15 == 0;
  }

  void _logWaitingForList(ChatJumpSeekSession session) {
    Logs().d(
      'Chat::scrollToEventId(): [gen=${session.request.generation}] waiting '
      'for list (openingState='
      '${openingChatViewStateNotifier.value.runtimeType}, '
      'timelineNull=${timeline == null})',
    );
  }

  Future<bool> _waitOneMountFrame(ChatJumpSeekSession session) async {
    if (!_isJumpCurrent(session.request)) return false;
    if (!_isChatEventListReady) {
      await SchedulerBinding.instance.endOfFrame;
      return false;
    }
    if (_isTargetRowBuilt(session.request)) {
      Logs().d(
        'Chat::scrollToEventId(): [gen=${session.request.generation}] '
        'GlobalObjectKey ready '
        '(displayIndex=${session.displayIndex}, '
        'finiteDy=${_targetDyInScrollViewport(session.request)})',
      );
      return true;
    }
    await SchedulerBinding.instance.endOfFrame;
    return false;
  }

  Future<bool> _waitUntilRowBuilt(ChatJumpSeekSession session) async {
    for (var frame = 0; frame < _maxMountFrames; frame++) {
      if (_shouldLogMountWait(frame)) {
        _logWaitingForList(session);
      }
      final ready = await _waitOneMountFrame(session);
      if (ready) return true;
      if (!_isJumpCurrent(session.request)) return false;
    }
    Logs().w(
      'Chat::scrollToEventId(): [gen=${session.request.generation}] '
      'GlobalObjectKey missing after $_maxMountFrames frames '
      '(displayIndex=${session.displayIndex}, openingState='
      '${openingChatViewStateNotifier.value.runtimeType})',
    );
    return _isTargetRowBuilt(session.request);
  }

  bool _hasFiniteTarget(ChatJumpRequest request) {
    return _targetDyInScrollViewport(request) != null;
  }

  /// Animates one seek page. Returns whether the target became finite.
  /// Returns `null` when the jump should stop (scroll edge).
  Future<bool?> _pageTowardTarget(ChatJumpSeekSession session) async {
    final position = scrollController.position;
    final page = position.viewportDimension * 0.85;
    final nearest = _findFiniteTimelineIndex();
    // No finite neighbor yet: move toward older history (typical after
    // contextual reload parks the viewport at the live/center edge).
    final towardOlder = nearest == null || session.targetIndex > nearest;
    final current = scrollController.offset;
    final raw = towardOlder ? current - page : current + page;
    final next = raw.clamp(position.minScrollExtent, position.maxScrollExtent);

    Logs().d(
      'Chat::scrollToEventId(): [gen=${session.request.generation}] seek '
      'towardOlder=$towardOlder nearest=$nearest '
      'target=${session.targetIndex} offset $current → $next',
    );

    if ((next - current).abs() < 1) {
      Logs().w(
        'Chat::scrollToEventId(): [gen=${session.request.generation}] '
        'seek hit scroll edge',
      );
      return null;
    }

    await scrollController.animateTo(
      next,
      duration: const Duration(milliseconds: 120),
      curve: Curves.linear,
    );
    await SchedulerBinding.instance.endOfFrame;
    return _hasFiniteTarget(session.request);
  }

  Future<_SeekPageOutcome> _runSeekPage(ChatJumpSeekSession session) async {
    if (!_isJumpCurrent(session.request) || !scrollController.hasClients) {
      return _SeekPageOutcome.stop;
    }
    if (_hasFiniteTarget(session.request)) {
      Logs().d(
        'Chat::scrollToEventId(): [gen=${session.request.generation}] '
        'finite position found during seek',
      );
      return _SeekPageOutcome.found;
    }

    final found = await _pageTowardTarget(session);
    if (found == null) return _SeekPageOutcome.stop;
    if (found) return _SeekPageOutcome.found;
    return _SeekPageOutcome.continueSeek;
  }

  Future<bool> _seekPagesUntilFinite(ChatJumpSeekSession session) async {
    for (var i = 0; i < _maxSeekPages; i++) {
      final outcome = await _runSeekPage(session);
      if (outcome == _SeekPageOutcome.found) return true;
      if (outcome == _SeekPageOutcome.stop) {
        return _hasFiniteTarget(session.request);
      }
    }
    return _hasFiniteTarget(session.request);
  }

  /// Page the viewport toward the session target until the row has a finite
  /// layout position (or we hit a scroll edge).
  ///
  /// Index 0 = newest. History is toward [ScrollPosition.minScrollExtent]
  /// (`_handleRequestHistory`), so older targets need a lower offset.
  Future<bool> _seekUntilFinitePosition(ChatJumpSeekSession session) async {
    if (!scrollController.hasClients) return false;
    if (_hasFiniteTarget(session.request)) return true;
    return _seekPagesUntilFinite(session);
  }

  /// Center a row that already has a finite viewport position.
  Future<void> _centerFiniteTarget(ChatJumpRequest request) async {
    final itemContext = GlobalObjectKey(request.eventId).currentContext;
    if (itemContext == null || !scrollController.hasClients) return;

    final itemBox = itemContext.findRenderObject() as RenderBox?;
    final scrollBox =
        scrollController.position.context.notificationContext
                ?.findRenderObject()
            as RenderBox?;
    if (itemBox == null || scrollBox == null) return;

    final itemPosition = itemBox.localToGlobal(
      Offset.zero,
      ancestor: scrollBox,
    );
    if (!itemPosition.dy.isFinite) return;

    final viewportHeight = scrollBox.size.height;
    final itemHeight = itemBox.size.height;
    final scrollAdjustment =
        itemPosition.dy - (viewportHeight / 2) + (itemHeight / 2);
    final targetOffset = (scrollController.offset + scrollAdjustment).clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    if ((targetOffset - scrollController.offset).abs() < 1) return;

    await scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _tryPackageScrollFallback(ChatJumpSeekSession session) async {
    Logs().w(
      'Chat::scrollToEventId(): [gen=${session.request.generation}] seek '
      'failed — trying scrollToIndex/ensureVisible fallback',
    );
    if (scrollController.hasClients &&
        scrollController.isIndexStateInLayoutRange(session.displayIndex)) {
      await scrollController.scrollToIndex(
        session.displayIndex,
        preferPosition: AutoScrollPosition.middle,
        duration: const Duration(milliseconds: 300),
      );
    }
    if (!_isJumpCurrent(session.request)) return;
    final keyContext = GlobalObjectKey(session.request.eventId).currentContext;
    if (keyContext == null || !keyContext.mounted) return;
    await Scrollable.ensureVisible(
      keyContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _centerIfFinite(ChatJumpSeekSession session) async {
    if (!_hasFiniteTarget(session.request)) return;
    Logs().d(
      'Chat::scrollToEventId(): [gen=${session.request.generation}] '
      'centering finite row displayIndex=${session.displayIndex}',
    );
    await _centerFiniteTarget(session.request);
  }

  void _startHighlightIfNeeded(ChatJumpSeekSession session) {
    if (!session.request.highlight) return;
    final highlightIndex =
        _visibleTimelineIndex(session.request) ?? session.targetIndex;
    Logs().d(
      'Chat::scrollToEventId(): [gen=${session.request.generation}] '
      'highlighting displayIndex='
      '${getDisplayEventIndex(highlightIndex)}',
    );
    // Do not await: highlight() animates for ~3s and would keep
    // `_isProgrammaticScrolling` true, blocking same-room URL jumps
    // (search result spam → "casino" / missed targets).
    unawaited(scrollController.highlight(getDisplayEventIndex(highlightIndex)));
  }

  Future<bool> _revealMountedTarget(ChatJumpSeekSession session) async {
    final gotFinite = await _seekUntilFinitePosition(session);
    if (!_isJumpCurrent(session.request)) return false;

    if (!gotFinite) {
      await _tryPackageScrollFallback(session);
    }

    if (!_isJumpCurrent(session.request)) return false;
    await _centerIfFinite(session);
    if (!_isJumpCurrent(session.request)) return false;

    final inViewport = _isTargetInViewport(session.request);
    Logs().d(
      'Chat::scrollToEventId(): [gen=${session.request.generation}] '
      'viewport check inViewport=$inViewport '
      'displayIndex=${session.displayIndex} '
      'dy=${_targetDyInScrollViewport(session.request)}',
    );
    if (!inViewport) {
      Logs().w(
        'Chat::scrollToEventId(): [gen=${session.request.generation}] '
        'failed to bring event ${session.request.eventId} into viewport',
      );
      return false;
    }

    _startHighlightIfNeeded(session);
    return true;
  }

  Future<int?> _reloadAndResolveIndex(ChatJumpRequest request) async {
    final eventCount = timeline?.events.length ?? 0;
    final index = _visibleTimelineIndex(request);
    final needsReload =
        index == null ||
        (request.allowContextualReload && eventCount > _jumpWindowMaxEvents);
    if (!needsReload) return index;

    // Missing from the live window and caller forbids contextual reload
    // (e.g. unread open): do not replace the live timeline.
    if (!request.allowContextualReload) {
      Logs().w(
        'Chat::scrollToEventId(): [gen=${request.generation}] event '
        '${request.eventId} not in live timeline '
        '(eventCount=$eventCount); skip contextual reload',
      );
      return index;
    }

    Logs().d(
      'Chat::scrollToEventId(): [gen=${request.generation}] reloading '
      'timeline (index=$index eventCount=$eventCount)',
    );
    await _reloadTimelineAroundEvent(request);
    if (!_isJumpCurrent(request)) {
      Logs().d(
        'Chat::scrollToEventId(): [gen=${request.generation}] superseded '
        'after reload (currentGeneration=$_scrollGeneration)',
      );
      return null;
    }
    final resolved = _visibleTimelineIndex(request);
    Logs().d(
      'Chat::scrollToEventId(): [gen=${request.generation}] post-reload '
      'lookup index=$resolved '
      '(timelineEventCount=${timeline?.events.length})',
    );
    return resolved;
  }

  ChatJumpSeekSession _seekSession(ChatJumpRequest request, int timelineIndex) {
    return ChatJumpSeekSession(
      request: request,
      targetIndex: timelineIndex,
      displayIndex: getDisplayEventIndex(timelineIndex),
    );
  }

  Future<bool> _jumpAfterMount(ChatJumpSeekSession session) async {
    await _raiseJumpMountCacheExtent();
    if (!_isJumpCurrent(session.request)) return false;

    final built = await _waitUntilRowBuilt(session);
    if (!_isJumpCurrent(session.request)) return false;
    if (!built) {
      Logs().w(
        'Chat::scrollToEventId(): [gen=${session.request.generation}] '
        'giving up — row never built '
        '(displayIndex=${session.displayIndex})',
      );
      return false;
    }

    final succeeded = await _revealMountedTarget(session);
    if (succeeded) {
      Logs().d(
        'Chat::scrollToEventId(): [gen=${session.request.generation}] DONE',
      );
    }
    return succeeded;
  }

  /// Lightweight scroll used when opening an unread room (`fullyRead`).
  ///
  /// Must not raise [jumpListCacheExtent] or hold `_isProgrammaticScrolling`
  /// for a multi-page seek — that races "scroll to live bottom → mark read"
  /// (see Patrol `UnreadBadgeClearsScenario`).
  Future<void> _scrollToEventInLiveTimeline(ChatJumpRequest request) async {
    final index = _visibleTimelineIndex(request);
    if (index == null || !scrollController.hasClients) {
      Logs().d(
        'Chat::_scrollToEventInLiveTimeline(): skip '
        '(index=$index hasClients=${scrollController.hasClients})',
      );
      return;
    }

    final displayIndex = getDisplayEventIndex(index);
    Logs().d(
      'Chat::_scrollToEventInLiveTimeline(): eventId=${request.eventId} '
      'displayIndex=$displayIndex',
    );

    if (scrollController.isIndexStateInLayoutRange(displayIndex)) {
      await scrollController.scrollToIndex(
        displayIndex,
        preferPosition: AutoScrollPosition.middle,
        duration: const Duration(milliseconds: 300),
      );
      await SchedulerBinding.instance.endOfFrame;
      return;
    }

    // A contextual jump may have started while the scroll above awaited —
    // do not let this lightweight scroll move the controller out from
    // under it.
    if (!_isJumpCurrent(request)) return;

    // Row not in tag map yet: one short ensureVisible attempt if the key
    // already mounted; otherwise leave the live timeline alone.
    final keyContext = GlobalObjectKey(request.eventId).currentContext;
    if (keyContext != null && keyContext.mounted) {
      if (!_isJumpCurrent(request)) return;
      await Scrollable.ensureVisible(
        keyContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _shouldUseLiveTimelineScroll(ChatJumpRequest request) {
    return !request.highlight && !request.allowContextualReload;
  }

  void _claimUrlHighlight(ChatJumpRequest request) {
    // Claim the URL highlight id up front so didUpdateWidget does not start
    // a second jump while we reload the contextual timeline.
    if (!request.highlight) return;
    _lastHighlightedEventId = request.eventId;
  }

  /// Returns whether the jump brought the target into view.
  ///
  /// `null` means the fast path did not apply (caller should reload/seek).
  Future<bool?> _tryRevealFastPathOrNull(ChatJumpRequest request) async {
    final index = _visibleTimelineIndex(request);
    Logs().d(
      'Chat::scrollToEventId(): [gen=${request.generation}] initial '
      'lookup index=$index '
      '(timelineEventCount=${timeline?.events.length})',
    );
    if (index == null) return null;

    final session = _seekSession(request, index);
    if (!_isFastPathReady(session)) return null;

    final succeeded = await _revealMountedTarget(session);
    if (succeeded) {
      Logs().d(
        'Chat::scrollToEventId(): [gen=${request.generation}] DONE (fast)',
      );
    }
    return succeeded;
  }

  Future<bool> _performContextualJump(ChatJumpRequest request) async {
    final fastResult = await _tryRevealFastPathOrNull(request);
    if (fastResult != null) return fastResult;

    final resolved = await _reloadAndResolveIndex(request);
    if (!_isJumpCurrent(request)) return false;
    if (resolved == null) {
      Logs().w(
        'Chat::scrollToEventId(): [gen=${request.generation}] Event '
        '${request.eventId} not found after timeline reload',
      );
      return false;
    }

    return _jumpAfterMount(_seekSession(request, resolved));
  }

  void _finishContextualJump(ChatJumpRequest request) {
    _restoreJumpCacheBaselineIfCurrent(request);
    _endProgrammaticScroll();
    Logs().d(
      'Chat::scrollToEventId(): [gen=${request.generation}] '
      'programmaticScrollDepth=$_programmaticScrollDepth '
      'isProgrammaticScrolling=$_isProgrammaticScrolling',
    );
  }

  void _releaseUrlHighlightClaimIfFailed(ChatJumpRequest request) {
    if (!request.highlight) return;
    if (request.generation != _scrollGeneration) return;
    if (_lastHighlightedEventId != request.eventId) return;
    _lastHighlightedEventId = null;
  }

  void _clearPendingUrlJumpIfMatching(ChatJumpRequest request) {
    if (_pendingUrlJumpEventId == request.eventId) {
      _pendingUrlJumpEventId = null;
    }
  }

  Future<void> _jumpToEventWithContext(ChatJumpRequest request) async {
    Logs().d(
      'Chat::scrollToEventId(): START eventId=${request.eventId} '
      'highlight=${request.highlight} '
      'allowContextualReload=${request.allowContextualReload} '
      'generation=${request.generation}',
    );
    _claimUrlHighlight(request);
    _beginProgrammaticScroll();
    _captureJumpCacheBaselineIfNeeded();
    var succeeded = false;
    try {
      succeeded = await _performContextualJump(request);
    } finally {
      // Failed jump must release the URL claim so the same search result
      // can be retried (otherwise `_scheduleJumpToUrlEventIfNeeded` no-ops).
      if (!succeeded) {
        _releaseUrlHighlightClaimIfFailed(request);
      }
      _clearPendingUrlJumpIfMatching(request);
      _finishContextualJump(request);
    }
  }

  Future<void> scrollToEventId(
    String eventId, {
    bool highlight = true,
    bool allowContextualReload = true,
  }) async {
    // Probe without bumping generation — live scroll must not supersede
    // an in-flight search jump.
    final probe = ChatJumpRequest(
      eventId: eventId,
      generation: _scrollGeneration,
      highlight: highlight,
      allowContextualReload: allowContextualReload,
    );

    // Unread-divider open path: stay on the live timeline without the
    // heavy jump machinery (cacheExtent / seek / programmatic lock).
    // Skip physical scroll while a contextual/URL jump owns the controller.
    if (_shouldUseLiveTimelineScroll(probe)) {
      if (_isProgrammaticScrolling) return;
      await _scrollToEventInLiveTimeline(probe);
      return;
    }

    await _jumpToEventWithContext(
      ChatJumpRequest(
        eventId: eventId,
        generation: ++_scrollGeneration,
        highlight: highlight,
        allowContextualReload: allowContextualReload,
      ),
    );
  }

  Future<void> scrollToEventIdAndHighlight(String eventId) async {
    return await scrollToEventId(eventId, highlight: true);
  }
}
