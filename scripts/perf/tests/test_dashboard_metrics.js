const test = require("node:test");
const assert = require("node:assert/strict");

require("../dashboard/metrics.js");

const {
  MIN_FRAME_SAMPLE,
  ROOM_ENTRY_SUMMARY,
  checkpointForSelection,
  hasEnoughFrames,
  isProfileRecord,
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
