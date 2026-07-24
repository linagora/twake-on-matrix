globalThis.PerfMetrics = (() => {
  "use strict";

  const MIN_FRAME_SAMPLE = 30;
  const MIN_WEB_FRAME_SAMPLE = 60;
  const MIN_WEB_FRAME_WINDOW_MS = 5000;
  const ROOM_ENTRY_SUMMARY = "room_enter_all";

  const isNumber = value => Number.isFinite(value);
  const sum = (values, key) => values.reduce(
    (total, value) => total + (value[key] || 0),
    0
  );

  function median(values) {
    if (!values.length) return null;
    const sorted = [...values].sort((left, right) => left - right);
    const middle = Math.floor(sorted.length / 2);
    return sorted.length % 2
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  function addUtcDays(value, amount) {
    const next = new Date(`${value}T00:00:00Z`);
    next.setUTCDate(next.getUTCDate() + amount);
    return next.toISOString().slice(0, 10);
  }

  function historyWindow(entries, range) {
    if (!entries.length) return null;
    const end = entries.at(-1).date;
    const start = range === "all"
      ? entries[0].date
      : addUtcDays(end, -(Number(range) - 1));
    return { start, end };
  }

  function maximumMarkerDelta(markers) {
    const deltas = markers.map(marker => marker?.delta).filter(isNumber);
    return deltas.length ? Math.max(...deltas) : null;
  }

  function platformDataPaths(platform) {
    return platform === "web"
      ? { index: "data/web/index.json", records: "data/web", family: "web" }
      : { index: "data/index.json", records: "data", family: "memory" };
  }

  function platformRecordCacheKey(platform, date) {
    return `${platform}:${date}`;
  }

  function isCurrentPlatformLoad(platform, loadId, currentPlatform, currentLoadId) {
    return platform === currentPlatform && loadId === currentLoadId;
  }

  function shouldFallbackToWeb(platform, status) {
    return platform === "android" && status === 404;
  }

  function isMetricApplicable(metric, scenario) {
    return !metric.continuousOnly || scenario.includes("scroll");
  }

  function metricSelection(metric, scenario, label) {
    return {
      scenario: metric.scenario || scenario,
      label: metric.checkpoint || label,
    };
  }

  function normalizeHealthIndex(values, lowerIsBetter) {
    const reference = values.find(value => isNumber(value) && value > 0);
    if (reference == null) return values.map(() => null);
    return values.map(value => {
      if (!isNumber(value) || value <= 0) return null;
      const index = lowerIsBetter
        ? (reference / value) * 100
        : (value / reference) * 100;
      return Number(index.toFixed(1));
    });
  }

  function classifySeries(values, lowerIsBetter) {
    return values.map((value, index) => {
      if (!isNumber(value)) return { severity: "missing", delta: null };
      const previous = values.slice(0, index).filter(isNumber).slice(-7);
      if (previous.length < 7) return { severity: "baseline", delta: null };
      const baseline = median(previous);
      if (!(baseline > 0)) return { severity: "baseline", delta: null };
      const delta = lowerIsBetter
        ? (value - baseline) / baseline
        : (baseline - value) / baseline;
      const severity = delta >= 0.2
        ? "critical"
        : delta >= 0.1
          ? "warning"
          : "normal";
      return { severity, delta, baseline };
    });
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
    const windowMs = sum(timed, "frame_window_ms");
    return windowMs > 0 ? intervals * 1000 / windowMs : null;
  }

  function summarizeRoomEntries(record, family, scenario) {
    const checkpoints = roomEntryCheckpoints(record, family, scenario);
    if (!checkpoints.length) return null;
    const last = checkpoints.at(-1);
    const frameCount = sum(checkpoints, "frame_count");
    const jankCount = sum(checkpoints, "jank_count");
    const transitions = checkpoints
      .map(checkpoint => checkpoint.transition_ms)
      .filter(isNumber);
    return {
      ...last,
      label: ROOM_ENTRY_SUMMARY,
      cycle_count: checkpoints.length,
      frame_count: frameCount,
      frame_window_ms: sum(checkpoints, "frame_window_ms"),
      fps: combinedFps(checkpoints),
      jank_count: jankCount,
      jank_rate: frameCount > 0 ? jankCount / frameCount : null,
      transition_ms: median(transitions),
    };
  }

  function checkpointForSelection(record, family, scenario, label) {
    if (label === ROOM_ENTRY_SUMMARY) {
      return summarizeRoomEntries(record, family, scenario);
    }
    return record?.[family]?.checkpoints.find(
      checkpoint => checkpoint.scenario === scenario && checkpoint.label === label
    ) ?? null;
  }

  function hasEnoughFrames(checkpoint) {
    return Number(checkpoint?.frame_count || 0) >= MIN_FRAME_SAMPLE;
  }

  function hasEnoughWebFrames(checkpoint) {
    return Number(checkpoint?.frame_count || 0) >= MIN_WEB_FRAME_SAMPLE &&
      Number(checkpoint?.frame_window_ms || 0) >= MIN_WEB_FRAME_WINDOW_MS;
  }

  function isProfileRecord(record) {
    return record?.environment?.build_mode === "profile";
  }

  return {
    MIN_FRAME_SAMPLE,
    MIN_WEB_FRAME_SAMPLE,
    MIN_WEB_FRAME_WINDOW_MS,
    ROOM_ENTRY_SUMMARY,
    checkpointForSelection,
    classifySeries,
    hasEnoughFrames,
    hasEnoughWebFrames,
    historyWindow,
    isProfileRecord,
    isMetricApplicable,
    maximumMarkerDelta,
    median,
    metricSelection,
    normalizeHealthIndex,
    platformDataPaths,
    platformRecordCacheKey,
    isCurrentPlatformLoad,
    shouldFallbackToWeb,
    summarizeRoomEntries,
  };
})();
