enum SentryTrackedEvents {
  // ── Sample (isExample: true → ignored by SentryLogger) ───────────────────
  failedToLoadTimeline('Failed to load timeline', isExample: true),
  // ── Active tracked events ─────────────────────────────────────────────────
  // pushHelperCrashed('Push Helper has crashed'),
  missingLastMessage('Missing-last-message'),
  wrongMemberCount('Wrong-member-count');

  const SentryTrackedEvents(this.message, {this.isExample = false});

  final String message;

  final bool isExample;

  static Iterable<SentryTrackedEvents> get active =>
      values.where((e) => !e.isExample);
}
