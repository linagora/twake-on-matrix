const test = require("node:test");
const assert = require("node:assert/strict");

require("../dashboard/metrics.js");

const {
  MIN_FRAME_SAMPLE,
  MIN_WEB_FRAME_SAMPLE,
  MIN_WEB_FRAME_WINDOW_MS,
  ROOM_ENTRY_SUMMARY,
  checkpointForSelection,
  classifySeries,
  hasEnoughFrames,
  hasEnoughWebFrames,
  historyWindow,
  isCurrentPlatformLoad,
  isMetricApplicable,
  isProfileRecord,
  maximumMarkerDelta,
  metricSelection,
  normalizeHealthIndex,
  platformDataPaths,
  platformRecordCacheKey,
  shouldFallbackToWeb,
  summarizeRoomEntries,
} = globalThis.PerfMetrics;

function record(checkpoints) {
  return {
    physical: { checkpoints },
    memory: { checkpoints },
  };
}

function roomEntry(cycle, changes = {}) {
  return {
    scenario: "nav_cycles",
    label: `room_enter_cycle${cycle}`,
    frame_count: 6,
    frame_window_ms: 83.335,
    jank_count: 1,
    jank_rate: 1 / 6,
    transition_ms: 1000 + cycle,
    rss_bytes: cycle * 100,
    ...changes,
  };
}

test("aggregates the five room openings with weighted frame metrics", () => {
  const summary = summarizeRoomEntries(
    record([1, 2, 3, 4, 5].map(cycle => roomEntry(cycle))),
    "physical",
    "nav_cycles"
  );

  assert.equal(summary.label, ROOM_ENTRY_SUMMARY);
  assert.equal(summary.cycle_count, 5);
  assert.equal(summary.frame_count, 30);
  assert.equal(summary.jank_count, 5);
  assert.equal(summary.jank_rate, 1 / 6);
  assert.equal(summary.transition_ms, 1003);
  assert.ok(Math.abs(summary.fps - 60) < 0.01);
});

test("keeps legacy FPS unavailable instead of deriving it from p95", () => {
  const checkpoints = [1, 2, 3, 4, 5].map(cycle => {
    const checkpoint = roomEntry(cycle);
    delete checkpoint.frame_window_ms;
    return checkpoint;
  });

  const summary = summarizeRoomEntries(
    record(checkpoints),
    "physical",
    "nav_cycles"
  );

  assert.equal(summary.fps, null);
});

test("rejects frame metrics below the minimum sample", () => {
  assert.equal(MIN_FRAME_SAMPLE, 30);
  assert.equal(hasEnoughFrames({ frame_count: 29 }), false);
  assert.equal(hasEnoughFrames({ frame_count: 30 }), true);
});

test("requires a meaningful Web frame count and measurement window", () => {
  assert.equal(MIN_WEB_FRAME_SAMPLE, 60);
  assert.equal(MIN_WEB_FRAME_WINDOW_MS, 5000);
  assert.equal(hasEnoughWebFrames({
    frame_count: 59,
    frame_window_ms: 5000,
  }), false);
  assert.equal(hasEnoughWebFrames({
    frame_count: 60,
    frame_window_ms: 4999,
  }), false);
  assert.equal(hasEnoughWebFrames({
    frame_count: 60,
    frame_window_ms: 5000,
  }), true);
});

test("keeps FPS out of transition scenarios", () => {
  const fpsMetric = { continuousOnly: true };
  assert.equal(isMetricApplicable(fpsMetric, "web_navigation"), false);
  assert.equal(isMetricApplicable(fpsMetric, "web_room_scroll"), true);
  assert.equal(isMetricApplicable({}, "web_navigation"), true);
});

test("normalizes the CI fluidity index without exposing absolute FPS", () => {
  assert.deepEqual(
    normalizeHealthIndex([20, null, 22, 18], false),
    [100, null, 110, 90]
  );
  assert.deepEqual(
    normalizeHealthIndex([800, 880], true),
    [100, 90.9]
  );
  assert.deepEqual(normalizeHealthIndex([null, 0], false), [null, null]);
});

test("keeps Web fluidity and transition sources independent", () => {
  assert.deepEqual(
    metricSelection(
      { scenario: "web_room_scroll", checkpoint: "scroll_completed" },
      "web_navigation",
      "room_opened"
    ),
    { scenario: "web_room_scroll", label: "scroll_completed" }
  );
  assert.deepEqual(
    metricSelection({}, "nav_cycles", "room_enter_all"),
    { scenario: "nav_cycles", label: "room_enter_all" }
  );
});

test("uses the final cycle RSS for the room-opening summary", () => {
  const daily = record([1, 2, 3, 4, 5].map(cycle => roomEntry(cycle)));
  const summary = checkpointForSelection(
    daily,
    "memory",
    "nav_cycles",
    ROOM_ENTRY_SUMMARY
  );

  assert.equal(summary.rss_bytes, 500);
});

test("rejects legacy debug records from performance comparisons", () => {
  assert.equal(isProfileRecord(record([])), false);
  assert.equal(isProfileRecord({ environment: { build_mode: "debug" } }), false);
  assert.equal(isProfileRecord({ environment: { build_mode: "profile" } }), true);
});

test("anchors a finite history window to the latest recorded night", () => {
  const entries = [
    { date: "2026-05-01" },
    { date: "2026-05-20" },
  ];

  assert.deepEqual(historyWindow(entries, "7"), {
    start: "2026-05-14",
    end: "2026-05-20",
  });
  assert.deepEqual(historyWindow(entries, "all"), {
    start: "2026-05-01",
    end: "2026-05-20",
  });
});

test("selects the largest available regression delta", () => {
  assert.equal(maximumMarkerDelta([
    { delta: 0.11 },
    { delta: null },
    { delta: 0.24 },
    { delta: -0.05 },
  ]), 0.24);
  assert.equal(maximumMarkerDelta([{ delta: null }, {}]), null);
});

test("keeps Android and Web history paths and families separate", () => {
  assert.deepEqual(platformDataPaths("android"), {
    index: "data/index.json",
    records: "data",
    family: "memory",
  });
  assert.deepEqual(platformDataPaths("web"), {
    index: "data/web/index.json",
    records: "data/web",
    family: "web",
  });
});

test("keeps platform caches and asynchronous loads isolated", () => {
  assert.equal(
    platformRecordCacheKey("android", "2026-07-24"),
    "android:2026-07-24"
  );
  assert.equal(
    platformRecordCacheKey("web", "2026-07-24"),
    "web:2026-07-24"
  );
  assert.equal(isCurrentPlatformLoad("web", 3, "web", 3), true);
  assert.equal(isCurrentPlatformLoad("android", 3, "web", 3), false);
  assert.equal(isCurrentPlatformLoad("web", 2, "web", 3), false);
});

test("falls back to Web only when the default Android index is missing", () => {
  assert.equal(shouldFallbackToWeb("android", 404), true);
  assert.equal(shouldFallbackToWeb("android", 500), false);
  assert.equal(shouldFallbackToWeb("web", 404), false);
});

test("uses seven prior points and ignores missing nights for a Web baseline", () => {
  const values = [100, 100, null, 100, 100, 100, 100, 100, 111];
  const markers = classifySeries(values, true);

  assert.equal(markers[7].severity, "baseline");
  assert.equal(markers[8].severity, "warning");
  assert.ok(Math.abs(markers[8].delta - 0.11) < 0.0001);
});
