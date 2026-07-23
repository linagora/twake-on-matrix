(function exposePerfMetrics(root, factory) {
  const metrics = factory();
  if (typeof module === "object" && module.exports) {
    module.exports = metrics;
  } else {
    root.PerfMetrics = metrics;
  }
})(typeof globalThis === "undefined" ? this : globalThis, () => {
  "use strict";

  const MIN_FRAME_SAMPLE = 30;
  const ROOM_ENTRY_SUMMARY = "room_enter_all";

  const isNumber = value => typeof value === "number" && Number.isFinite(value);

  function median(values) {
    if (!values.length) return null;
    const sorted = [...values].sort((left, right) => left - right);
    const middle = Math.floor(sorted.length / 2);
    return sorted.length % 2
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  function roomEntryCheckpoints(record, family, scenario) {
    return (record?.[family]?.checkpoints || []).filter(
      checkpoint => checkpoint.scenario === scenario &&
        /^room_enter_cycle\d+$/.test(checkpoint.label)
    );
  }

  function combinedFps(checkpoints) {
    const rendered = checkpoints.filter(checkpoint => checkpoint.frame_count > 0);
    const timed = rendered.filter(checkpoint => (
      checkpoint.frame_count >= 2 &&
      isNumber(checkpoint.frame_window_ms) &&
      checkpoint.frame_window_ms > 0
    ));
    if (!rendered.length || timed.length !== rendered.length) return null;
    const intervals = timed.reduce(
      (total, checkpoint) => total + checkpoint.frame_count - 1,
      0
    );
    const windowMs = timed.reduce(
      (total, checkpoint) => total + checkpoint.frame_window_ms,
      0
    );
    return windowMs > 0 ? intervals * 1000 / windowMs : null;
  }

  function summarizeRoomEntries(record, family, scenario) {
    const checkpoints = roomEntryCheckpoints(record, family, scenario);
    if (!checkpoints.length) return null;
    const last = checkpoints.at(-1);
    const frameCount = checkpoints.reduce(
      (total, checkpoint) => total + (checkpoint.frame_count || 0),
      0
    );
    const jankCounts = checkpoints.map(checkpoint => checkpoint.jank_count);
    const jankCount = jankCounts.every(isNumber)
      ? jankCounts.reduce((total, value) => total + value, 0)
      : null;
    const transitions = checkpoints
      .map(checkpoint => checkpoint.transition_ms)
      .filter(isNumber);
    return {
      ...last,
      label: ROOM_ENTRY_SUMMARY,
      cycle_count: checkpoints.length,
      frame_count: frameCount,
      frame_window_ms: checkpoints.reduce(
        (total, checkpoint) => total + (checkpoint.frame_window_ms || 0),
        0
      ),
      fps: combinedFps(checkpoints),
      jank_count: jankCount,
      jank_rate: jankCount == null || frameCount <= 0 ? null : jankCount / frameCount,
      transition_ms: median(transitions),
    };
  }

  function checkpointForSelection(record, family, scenario, label) {
    if (label === ROOM_ENTRY_SUMMARY) {
      return summarizeRoomEntries(record, family, scenario);
    }
    return record?.[family]?.checkpoints.find(
      checkpoint => checkpoint.scenario === scenario && checkpoint.label === label
    ) || null;
  }

  function hasEnoughFrames(checkpoint) {
    return isNumber(checkpoint?.frame_count) &&
      checkpoint.frame_count >= MIN_FRAME_SAMPLE;
  }

  function isProfileRecord(record) {
    return record?.environment?.build_mode === "profile";
  }

  return {
    MIN_FRAME_SAMPLE,
    ROOM_ENTRY_SUMMARY,
    checkpointForSelection,
    hasEnoughFrames,
    isProfileRecord,
    median,
    summarizeRoomEntries,
  };
});
