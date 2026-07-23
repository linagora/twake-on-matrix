(() => {
  "use strict";

  const METRICS = {
    rss_bytes: { label: "RSS memory", format: value => `${(value / 1048576).toFixed(1)} MiB` },
    build_p95_us: { label: "Build p95", format: value => `${(value / 1000).toFixed(1)} ms` },
    raster_p95_us: { label: "Raster p95", format: value => `${(value / 1000).toFixed(1)} ms` },
    jank_rate: { label: "Jank rate", format: value => `${(value * 100).toFixed(1)}%` },
    transition_ms: { label: "Transition time", format: value => `${value.toFixed(1)} ms` },
  };

  const state = { index: null, records: [], historyRecords: [], recordCache: new Map(), windowStart: null, windowEnd: null, memoryChart: null, physicalChart: null };
  const elements = Object.fromEntries([
    "range-select", "scenario-select", "checkpoint-select", "metric-select",
    "latest-date", "latest-sha", "latest-memory", "latest-physical", "history-depth",
    "status-light", "status-label", "status-meta", "inspection-title", "inspection-values",
  ].map(id => [id, document.getElementById(id)]));

  const isoDay = date => date.toISOString().slice(0, 10);
  const parseDay = value => new Date(`${value}T00:00:00Z`);
  const addDays = (value, amount) => {
    const next = parseDay(value);
    next.setUTCDate(next.getUTCDate() + amount);
    return isoDay(next);
  };

  function median(values) {
    const sorted = [...values].sort((left, right) => left - right);
    const middle = Math.floor(sorted.length / 2);
    return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  function classify(values) {
    return values.map((value, index) => {
      if (value == null) return { severity: "missing", delta: null };
      const baselineValues = values.slice(0, index).filter(item => item != null).slice(-7);
      if (baselineValues.length < 7) return { severity: "baseline", delta: null };
      const baseline = median(baselineValues);
      if (baseline <= 0) return { severity: "baseline", delta: null };
      const delta = (value - baseline) / baseline;
      return { severity: delta >= 0.2 ? "critical" : delta >= 0.1 ? "warning" : "normal", delta, baseline };
    });
  }

  function selectedEntries() {
    if (!state.index?.entries.length) return [];
    const range = elements["range-select"].value;
    const lastRecordedDay = state.index.entries[state.index.entries.length - 1].date;
    state.windowEnd = [lastRecordedDay, isoDay(new Date())].sort().at(-1);
    state.windowStart = range === "all"
      ? state.index.entries[0].date
      : addDays(state.windowEnd, -(Number(range) - 1));
    return state.index.entries.filter(entry => entry.date >= state.windowStart && entry.date <= state.windowEnd);
  }

  async function loadSelectedRecords() {
    const entries = selectedEntries();
    const firstEntryIndex = state.index.entries.findIndex(entry => entry.date === entries[0]?.date);
    const entriesWithBaseline = state.index.entries.slice(Math.max(0, firstEntryIndex - 7));
    const loadedRecords = (await Promise.all(entriesWithBaseline.map(async entry => {
      if (!state.recordCache.has(entry.date)) {
        const response = await fetch(`data/${entry.file}`, { cache: "no-store" });
        if (!response.ok) throw new Error(`Cannot load ${entry.file}`);
        state.recordCache.set(entry.date, await response.json());
      }
      return state.recordCache.get(entry.date);
    }))).sort((left, right) => left.date.localeCompare(right.date));
    const selectedDates = new Set(entries.map(entry => entry.date));
    state.historyRecords = loadedRecords;
    state.records = loadedRecords.filter(record => selectedDates.has(record.date));
  }

  function calendarDays() {
    const days = [];
    for (let day = state.windowStart; day <= state.windowEnd; day = addDays(day, 1)) days.push(day);
    return days;
  }

  function checkpoint(record, family, scenario, label) {
    return record?.[family]?.checkpoints.find(item => item.scenario === scenario && item.label === label);
  }

  function populateScenarios() {
    const scenarios = [...new Set(state.records.flatMap(record => record.memory.checkpoints.map(item => item.scenario)))].sort();
    const previous = elements["scenario-select"].value;
    elements["scenario-select"].replaceChildren(...scenarios.map(value => new Option(value.replaceAll("_", " "), value)));
    if (scenarios.includes(previous)) elements["scenario-select"].value = previous;
    populateCheckpoints();
  }

  function populateCheckpoints() {
    const scenario = elements["scenario-select"].value;
    const labels = [...new Set(state.records.flatMap(record => record.memory.checkpoints.filter(item => item.scenario === scenario).map(item => item.label)))];
    const previous = elements["checkpoint-select"].value;
    elements["checkpoint-select"].replaceChildren(...labels.map(value => new Option(value.replaceAll("_", " "), value)));
    if (labels.includes(previous)) elements["checkpoint-select"].value = previous;
    render();
  }

  function chartOptions(metric, source) {
    return {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { intersect: false, mode: "index" },
      animation: { duration: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? 0 : 500 },
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: "#f3f0e7",
          titleColor: "#071013",
          bodyColor: "#071013",
          borderColor: "#071013",
          borderWidth: 1,
          padding: 12,
          callbacks: {
            label: context => `${context.dataset.label}: ${METRICS[metric].format(context.raw)}`,
            afterBody: contexts => {
              const marker = contexts[0]?.dataset?.markers?.[contexts[0].dataIndex];
              return marker?.delta != null ? [`Δ 7-night median: +${(marker.delta * 100).toFixed(1)}%`] : [];
            },
          },
        },
      },
      scales: {
        x: { grid: { color: "rgba(148,155,157,.12)" }, ticks: { color: "#949b9d", maxRotation: 0, autoSkip: true, maxTicksLimit: 8 } },
        y: { beginAtZero: false, grid: { color: "rgba(148,155,157,.12)" }, ticks: { color: "#949b9d", callback: value => METRICS[metric].format(value) } },
      },
      onClick: (_event, points, chart) => {
        if (!points.length) return;
        inspectPoint(source, chart.data.calendarDays[points[0].index], chart.data.markers[points[0].index]);
      },
    };
  }

  function pointColors(markers, normalColor) {
    return markers.map(marker => marker.severity === "critical" ? "#ff5d52" : marker.severity === "warning" ? "#ffb547" : normalColor);
  }

  function markersFor(selection, visibleDays) {
    const { family, scenario, label, metric } = selection;
    const historyValues = state.historyRecords.map(record => checkpoint(record, family, scenario, label)?.[metric] ?? null);
    const historyMarkers = classify(historyValues);
    const markersByDay = new Map(
      state.historyRecords.map((record, index) => [record.date, historyMarkers[index]])
    );
    return visibleDays.map(day => markersByDay.get(day) || { severity: "missing", delta: null });
  }

  function variabilityDatasets(values, deviations) {
    return [
      { label: "Median − σ", data: values.map((value, index) => value == null ? null : Math.max(0, value - (deviations[index] || 0))), borderColor: "rgba(183,243,74,.22)", pointRadius: 0, borderDash: [4, 5], tension: 0.22, spanGaps: false },
      { label: "Median + σ", data: values.map((value, index) => value == null ? null : value + (deviations[index] || 0)), borderColor: "rgba(183,243,74,.22)", backgroundColor: "rgba(183,243,74,.07)", fill: "-1", pointRadius: 0, borderDash: [4, 5], tension: 0.22, spanGaps: false },
    ];
  }

  function measurementDataset(source, values, markers, normalColor) {
    return {
      label: source === "memory" ? "Virtual median" : "Physical single run",
      data: values,
      borderColor: normalColor,
      backgroundColor: pointColors(markers, normalColor),
      pointBorderColor: "#071013",
      pointBorderWidth: 2,
      pointRadius: markers.map(marker => ["warning", "critical"].includes(marker.severity) ? 6 : 3),
      pointHoverRadius: 7,
      borderWidth: 2,
      tension: 0.22,
      spanGaps: false,
      markers,
    };
  }

  function chartDatasets(source, values, deviations, markers) {
    const normalColor = source === "memory" ? "#b7f34a" : "#70d6d2";
    const measurement = measurementDataset(source, values, markers, normalColor);
    return source === "memory"
      ? [...variabilityDatasets(values, deviations), measurement]
      : [measurement];
  }

  function renderChart(config) {
    const { existingChart, canvasId, source, labels, values, deviations, metric, markers } = config;
    existingChart?.destroy();
    const datasets = chartDatasets(source, values, deviations, markers);
    const chart = new Chart(document.getElementById(canvasId), {
      type: "line",
      data: { labels: labels.map(day => day.slice(5)), datasets },
      options: chartOptions(metric, source),
    });
    chart.data.calendarDays = labels;
    chart.data.markers = markers;
    return chart;
  }

  function inspectPoint(source, day, marker) {
    const record = state.records.find(item => item.date === day);
    if (!record) return;
    const metric = elements["metric-select"].value;
    const scenario = elements["scenario-select"].value;
    const label = elements["checkpoint-select"].value;
    const selected = checkpoint(record, source, scenario, label);
    const previous = [...state.records].reverse().find(item => item.date < day);
    const compareUrl = previous ? `https://github.com/linagora/twake-on-matrix/compare/${previous.commit.sha}...${record.commit.sha}` : null;
    elements["inspection-title"].textContent = `${day} · ${source === "memory" ? "virtual median" : "physical run"}`;
    elements["inspection-values"].innerHTML = `
      <dl><dt>${METRICS[metric].label}</dt><dd>${selected?.[metric] == null ? "Not measured" : METRICS[metric].format(selected[metric])}</dd></dl>
      <dl><dt>Regression marker</dt><dd>${marker?.delta == null ? "Baseline unavailable" : `+${(marker.delta * 100).toFixed(1)}% vs 7-night median`}</dd></dl>
      <dl><dt>Commit</dt><dd><a href="${record.commit.url}">${record.commit.sha.slice(0, 9)} ↗</a></dd></dl>
      <dl><dt>Evidence</dt><dd><a href="${record.run.url}">Actions run ${record.run.id} ↗</a>${compareUrl ? ` · <a href="${compareUrl}">Compare ↗</a>` : ""}</dd></dl>`;
  }

  function currentSelection() {
    return {
      scenario: elements["scenario-select"].value,
      label: elements["checkpoint-select"].value,
      metric: elements["metric-select"].value,
    };
  }

  function hasRenderableSelection(selection) {
    return [state.records.length, selection.scenario, selection.label].every(Boolean);
  }

  function chartSeries(family, selection, days, recordsByDay) {
    const { scenario, label, metric } = selection;
    const checkpoints = days.map(day => checkpoint(recordsByDay.get(day), family, scenario, label));
    return {
      values: checkpoints.map(item => item?.[metric] ?? null),
      deviations: checkpoints.map(item => item?.[`${metric}_stddev`] ?? 0),
      markers: markersFor({ family, ...selection }, days),
    };
  }

  function updateLatestCards(latest, selection) {
    const { scenario, label, metric } = selection;
    const latestMemory = checkpoint(latest, "memory", scenario, label)?.[metric];
    const latestPhysical = checkpoint(latest, "physical", scenario, label)?.[metric];
    elements["latest-date"].textContent = latest.date;
    elements["latest-sha"].innerHTML = `<a href="${latest.commit.url}">${latest.commit.sha.slice(0, 9)} ↗</a>`;
    elements["latest-memory"].textContent = latestMemory == null ? "—" : METRICS[metric].format(latestMemory);
    elements["latest-physical"].textContent = latestPhysical == null ? "—" : METRICS[metric].format(latestPhysical);
  }

  function replaceChart(family, series, selection, days) {
    const stateKey = family === "memory" ? "memoryChart" : "physicalChart";
    state[stateKey] = renderChart({
      existingChart: state[stateKey],
      canvasId: `${family}-chart`,
      source: family,
      labels: days,
      metric: selection.metric,
      ...series,
    });
  }

  function render() {
    const selection = currentSelection();
    if (!hasRenderableSelection(selection)) return;
    const days = calendarDays();
    const recordsByDay = new Map(state.records.map(record => [record.date, record]));
    const memorySeries = chartSeries("memory", selection, days, recordsByDay);
    const physicalSeries = chartSeries("physical", selection, days, recordsByDay);

    replaceChart("memory", memorySeries, selection, days);
    replaceChart("physical", physicalSeries, selection, days);
    updateLatestCards(state.records.at(-1), selection);
  }

  function validateIndex(index) {
    if (index.schema_version !== 1) throw new Error("Unsupported dataset schema");
    if (!Array.isArray(index.entries)) throw new Error("Unsupported dataset schema");
  }

  function markDatasetReady() {
    elements["history-depth"].textContent = `${state.index.entries.length} nights`;
    elements["status-light"].classList.add("ready");
    elements["status-label"].textContent = "Dataset online";
    elements["status-meta"].textContent = `Updated ${state.index.updated_at || state.records.at(-1).generated_at}`;
  }

  function showDatasetError(error) {
    elements["status-light"].classList.add("error");
    elements["status-label"].textContent = "Dataset unavailable";
    elements["status-meta"].textContent = error.message;
    elements["inspection-title"].textContent = "No performance history available";
    elements["inspection-values"].innerHTML = `<p>${error.message}. The dashboard will populate after the first successful nightly publication.</p>`;
  }

  async function fetchIndex() {
    const response = await fetch("data/index.json", { cache: "no-store" });
    if (!response.ok) throw new Error(`Dataset index returned HTTP ${response.status}`);
    const index = await response.json();
    validateIndex(index);
    return index;
  }

  async function load() {
    state.index = await fetchIndex();
    await loadSelectedRecords();
    if (!state.records.length) throw new Error("The nightly dataset is empty");
    markDatasetReady();
    populateScenarios();
  }

  async function reloadSelectedRange() {
    await loadSelectedRecords();
    populateScenarios();
  }

  function reportRangeError(error) {
    elements["status-light"].classList.add("error");
    elements["status-label"].textContent = "Dataset unavailable";
    elements["status-meta"].textContent = error.message;
  }

  elements["range-select"].addEventListener("change", () => {
    reloadSelectedRange().catch(reportRangeError);
  });
  elements["metric-select"].addEventListener("change", render);
  elements["scenario-select"].addEventListener("change", populateCheckpoints);
  elements["checkpoint-select"].addEventListener("change", render);
  load().catch(showDatasetError);
})();
