(() => {
  "use strict";

  const {
    MIN_FRAME_SAMPLE,
    ROOM_ENTRY_SUMMARY,
    checkpointForSelection,
    hasEnoughFrames,
    isProfileRecord,
    median,
  } = globalThis.PerfMetrics;

  const SCENARIO_LABELS = {
    nav_cycles: "Ouverture répétée d’une conversation",
    scroll_room1: "Scroll d’une conversation riche en images · salle 1",
    scroll_room2: "Scroll d’une conversation riche en images · salle 2",
    chat_list_scroll: "Scroll de la liste des conversations",
  };

  const CHECKPOINT_LABELS = {
    chat_list_baseline: "Liste avant les ouvertures",
    room_entered: "Conversation ouverte",
    scroll_end: "Fin du scroll",
    scroll_settled: "Après stabilisation",
    back_to_list: "Retour à la liste",
    list_top: "Haut de la liste",
    list_bottom: "Bas de la liste",
    list_top_again: "Retour en haut",
  };

  const METRICS = {
    rss_bytes: {
      label: "Mémoire",
      source: "memory",
      color: "#b8f34b",
      lowerIsBetter: true,
      format: value => `${(value / 1048576).toFixed(1)} Mio`,
      read: checkpointValue => checkpointValue?.rss_bytes ?? null,
      valueElement: "value-rss",
      metaElement: "meta-rss",
    },
    fps: {
      label: "FPS mesurés",
      source: "physical",
      color: "#65d9d2",
      lowerIsBetter: false,
      continuousOnly: true,
      format: value => `${value.toFixed(1)} FPS`,
      read: checkpointValue => hasEnoughFrames(checkpointValue) &&
        checkpointValue.fps > 0 ? checkpointValue.fps : null,
      valueElement: "value-fps",
      metaElement: "meta-fps",
    },
    jank_rate: {
      label: "Frames saccadées",
      source: "physical",
      color: "#ffb548",
      lowerIsBetter: true,
      format: value => `${(value * 100).toFixed(1)} %`,
      read: checkpointValue => hasEnoughFrames(checkpointValue)
        ? checkpointValue.jank_rate ?? null
        : null,
      valueElement: "value-jank",
      metaElement: "meta-jank",
    },
    transition_ms: {
      label: "Temps d’ouverture",
      source: "physical",
      color: "#78a9ff",
      lowerIsBetter: true,
      format: value => `${value.toFixed(0)} ms`,
      read: checkpointValue => checkpointValue?.transition_ms ?? null,
      valueElement: "value-transition",
      metaElement: "meta-transition",
    },
  };

  const state = {
    index: null,
    records: [],
    historyRecords: [],
    recordCache: new Map(),
    windowStart: null,
    windowEnd: null,
    overviewChart: null,
  };

  const elementIds = [
    "range-select", "scenario-select", "checkpoint-select",
    "latest-date", "latest-sha", "history-depth",
    "status-light", "status-label", "status-meta",
    "overall-status", "overall-detail", "verdict",
    "inspection-title", "inspection-values", "overview-chart",
    ...Object.values(METRICS).flatMap(metric => [metric.valueElement, metric.metaElement]),
  ];
  const elements = Object.fromEntries(elementIds.map(id => [id, document.getElementById(id)]));

  const isoDay = date => date.toISOString().slice(0, 10);
  const parseDay = value => new Date(`${value}T00:00:00Z`);
  const addDays = (value, amount) => {
    const next = parseDay(value);
    next.setUTCDate(next.getUTCDate() + amount);
    return isoDay(next);
  };

  function severityForDelta(delta) {
    if (delta >= 0.2) return "critical";
    if (delta >= 0.1) return "warning";
    return "normal";
  }

  function classify(values, lowerIsBetter) {
    return values.map((value, index) => {
      if (value == null) return { severity: "missing", delta: null };
      const previous = values.slice(0, index).filter(item => item != null).slice(-7);
      if (previous.length < 7) return { severity: "baseline", delta: null };
      const baseline = median(previous);
      if (baseline <= 0) return { severity: "baseline", delta: null };
      const delta = lowerIsBetter
        ? (value - baseline) / baseline
        : (baseline - value) / baseline;
      return { severity: severityForDelta(delta), delta, baseline };
    });
  }

  function selectedEntries() {
    if (!state.index?.entries.length) return [];
    const range = elements["range-select"].value;
    const lastRecordedDay = state.index.entries.at(-1).date;
    state.windowEnd = [lastRecordedDay, isoDay(new Date())].sort().at(-1);
    state.windowStart = range === "all"
      ? state.index.entries[0].date
      : addDays(state.windowEnd, -(Number(range) - 1));
    return state.index.entries.filter(entry => entry.date >= state.windowStart && entry.date <= state.windowEnd);
  }

  async function fetchRecord(entry) {
    if (state.recordCache.has(entry.date)) return state.recordCache.get(entry.date);
    const response = await fetch(`data/${entry.file}`, { cache: "no-store" });
    if (!response.ok) throw new Error(`Impossible de charger ${entry.file}`);
    const record = await response.json();
    state.recordCache.set(entry.date, record);
    return record;
  }

  async function loadSelectedRecords() {
    const entries = selectedEntries();
    const firstIndex = state.index.entries.findIndex(entry => entry.date === entries[0]?.date);
    const entriesWithBaseline = state.index.entries.slice(Math.max(0, firstIndex - 7));
    const loaded = (await Promise.all(entriesWithBaseline.map(fetchRecord)))
      .sort((left, right) => left.date.localeCompare(right.date));
    const selectedDates = new Set(entries.map(entry => entry.date));
    state.historyRecords = loaded;
    state.records = loaded.filter(record => selectedDates.has(record.date));
  }

  function calendarDays() {
    const days = [];
    for (let day = state.windowStart; day <= state.windowEnd; day = addDays(day, 1)) {
      days.push(day);
    }
    return days;
  }

  function checkpoint(record, family, scenario, label) {
    return checkpointForSelection(record, family, scenario, label);
  }

  function metricValue(record, metric, scenario, label) {
    if (!isProfileRecord(record)) return null;
    if (metric.continuousOnly && !scenario.includes("scroll")) return null;
    return metric.read(checkpoint(record, metric.source, scenario, label));
  }

  function scenarioLabel(value) {
    return SCENARIO_LABELS[value] || value.replaceAll("_", " ");
  }

  function checkpointLabel(value) {
    if (value === ROOM_ENTRY_SUMMARY) return "Ouverture des conversations · 5 cycles";
    const cycleMatch = value.match(/^room_enter_cycle(\d+)$/);
    if (cycleMatch) return `Conversation ouverte · cycle ${cycleMatch[1]}`;
    const returnMatch = value.match(/^chat_list_after_cycle(\d+)$/);
    if (returnMatch) return `Retour à la liste · cycle ${returnMatch[1]}`;
    const scrollMatch = value.match(/^(room\d+)_scroll_step_(\d+)of(\d+)$/);
    if (scrollMatch) return `Scroll intermédiaire · étape ${scrollMatch[2]}/${scrollMatch[3]}`;
    return CHECKPOINT_LABELS[value] || value.replaceAll("_", " ");
  }

  function populateScenarios() {
    const available = [...new Set(
      state.records.flatMap(record => record.memory.checkpoints.map(item => item.scenario))
    )];
    available.sort((left, right) => {
      if (left === "nav_cycles") return -1;
      if (right === "nav_cycles") return 1;
      return left.localeCompare(right);
    });
    const previous = elements["scenario-select"].value;
    elements["scenario-select"].replaceChildren(
      ...available.map(value => new Option(scenarioLabel(value), value))
    );
    elements["scenario-select"].value = available.includes(previous)
      ? previous
      : available[0] || "";
    populateCheckpoints();
  }

  function populateCheckpoints() {
    const scenario = elements["scenario-select"].value;
    const labels = [...new Set(state.records.flatMap(record =>
      record.memory.checkpoints
        .filter(item => item.scenario === scenario)
        .map(item => item.label)
    ))];
    if (scenario === "nav_cycles" && labels.some(label => /^room_enter_cycle\d+$/.test(label))) {
      labels.unshift(ROOM_ENTRY_SUMMARY);
    }
    const previous = elements["checkpoint-select"].value;
    elements["checkpoint-select"].replaceChildren(
      ...labels.map(value => new Option(checkpointLabel(value), value))
    );
    const preferred = labels.includes(ROOM_ENTRY_SUMMARY)
      ? ROOM_ENTRY_SUMMARY
      : labels.at(-1);
    elements["checkpoint-select"].value = labels.includes(previous)
      ? previous
      : preferred || "";
    render();
  }

  function markersFor(metric, scenario, label, visibleDays) {
    const values = state.historyRecords.map(record => metricValue(record, metric, scenario, label));
    const markers = classify(values, metric.lowerIsBetter);
    const byDay = new Map(state.historyRecords.map((record, index) => [record.date, markers[index]]));
    return visibleDays.map(day => byDay.get(day) || { severity: "missing", delta: null });
  }

  function normalize(values, lowerIsBetter) {
    const reference = values.find(value => value != null && value > 0);
    if (reference == null) return values.map(() => null);
    return values.map(value => {
      if (value == null || value <= 0) return null;
      const index = lowerIsBetter ? (reference / value) * 100 : (value / reference) * 100;
      return Number(index.toFixed(1));
    });
  }

  function pointColors(markers, normalColor) {
    return markers.map(marker => {
      if (marker.severity === "critical") return "#ff6257";
      if (marker.severity === "warning") return "#ffb548";
      return normalColor;
    });
  }

  function buildDataset(metricKey, days, recordsByDay, selection) {
    const metric = METRICS[metricKey];
    const realValues = days.map(day => (
      metricValue(recordsByDay.get(day), metric, selection.scenario, selection.label)
    ));
    const markers = markersFor(metric, selection.scenario, selection.label, days);
    return {
      label: metric.label,
      data: normalize(realValues, metric.lowerIsBetter),
      realValues,
      markers,
      metricKey,
      borderColor: metric.color,
      backgroundColor: pointColors(markers, metric.color),
      pointBorderColor: "#061013",
      pointBorderWidth: 2,
      pointRadius: markers.map(marker => ["warning", "critical"].includes(marker.severity) ? 6 : 3),
      pointHoverRadius: 7,
      borderWidth: 2.5,
      tension: 0.2,
      spanGaps: false,
    };
  }

  function chartOptions(days) {
    return {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { intersect: false, mode: "index" },
      animation: {
        duration: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? 0 : 450,
      },
      plugins: {
        legend: {
          display: true,
          position: "top",
          align: "start",
          labels: { color: "#c8d0d1", usePointStyle: true, boxWidth: 8, padding: 18 },
        },
        tooltip: {
          backgroundColor: "#f3f0e7",
          titleColor: "#061013",
          bodyColor: "#061013",
          borderColor: "#061013",
          borderWidth: 1,
          padding: 13,
          callbacks: {
            label: context => {
              const metric = METRICS[context.dataset.metricKey];
              const realValue = context.dataset.realValues[context.dataIndex];
              if (realValue == null) return `${metric.label} : non mesuré`;
              return `${metric.label} : ${metric.format(realValue)} · indice ${context.raw}`;
            },
            afterBody: contexts => {
              const marker = contexts
                .map(context => context.dataset.markers[context.dataIndex])
                .find(item => item?.delta != null);
              return marker ? [`Écart défavorable maximal : +${(marker.delta * 100).toFixed(1)} %`] : [];
            },
          },
        },
      },
      scales: {
        x: {
          grid: { color: "rgba(155,166,168,.1)" },
          ticks: { color: "#9ba6a8", maxRotation: 0, autoSkip: true, maxTicksLimit: 9 },
        },
        y: {
          suggestedMin: 75,
          suggestedMax: 125,
          grid: { color: "rgba(155,166,168,.12)" },
          ticks: { color: "#9ba6a8", callback: value => `${value}` },
          title: { display: true, color: "#9ba6a8", text: "Indice de santé · 100 = référence" },
        },
      },
      onClick: (_event, points) => {
        if (!points.length) return;
        inspectPoint(days[points[0].index]);
      },
    };
  }

  function renderChart(days, datasets) {
    state.overviewChart?.destroy();
    state.overviewChart = new Chart(elements["overview-chart"], {
      type: "line",
      data: { labels: days.map(day => day.slice(5)), datasets },
      options: chartOptions(days),
    });
  }

  function severityCopy(marker) {
    if (marker?.severity === "critical") return "Dégradation critique";
    if (marker?.severity === "warning") return "À surveiller";
    if (marker?.severity === "normal") return "Stable";
    return "Référence en construction";
  }

  function frameSampleCopy(checkpointValue, metricKey, marker, scenario) {
    if (metricKey === "fps" && !scenario.includes("scroll")) {
      return "Non applicable sur une transition · choisissez un scénario de scroll";
    }
    const frameCount = checkpointValue?.frame_count ?? 0;
    if (frameCount < MIN_FRAME_SAMPLE) {
      return `${frameCount} frames · minimum ${MIN_FRAME_SAMPLE} · données insuffisantes`;
    }
    if (metricKey === "fps" && !(checkpointValue?.fps > 0)) {
      return `${frameCount} frames · FPS disponibles dès le prochain run profile`;
    }
    return `${frameCount} frames analysées · ${severityCopy(marker)}`;
  }

  function updateMetricCards(latest, scenario, label, latestMarkers) {
    Object.entries(METRICS).forEach(([metricKey, metric]) => {
      const valueElement = elements[metric.valueElement];
      const metaElement = elements[metric.metaElement];
      const card = valueElement.closest(".metric-card");
      if (!isProfileRecord(latest)) {
        card.classList.remove("warning", "critical");
        valueElement.classList.add("insufficient");
        valueElement.textContent = "Prochain nightly";
        metaElement.textContent = "Ancien run debug ignoré · APK profile requis";
        return;
      }
      const value = metricValue(latest, metric, scenario, label);
      const marker = latestMarkers[metricKey];
      card.classList.remove("warning", "critical");
      if (["warning", "critical"].includes(marker?.severity)) {
        card.classList.add(marker.severity);
      }
      const physicalCheckpoint = checkpoint(latest, "physical", scenario, label);
      const isFrameMetric = metricKey === "fps" || metricKey === "jank_rate";
      const isInapplicable = metricKey === "fps" && !scenario.includes("scroll");
      const awaitsProfileRun = metricKey === "fps" &&
        hasEnoughFrames(physicalCheckpoint) &&
        value == null;
      valueElement.classList.toggle("insufficient", value == null && isFrameMetric);
      valueElement.textContent = isInapplicable
        ? "Non applicable"
        : awaitsProfileRun ? "Prochain nightly"
        : value == null && isFrameMetric ? "Données insuffisantes"
        : value == null ? "Non mesuré" : metric.format(value);
      if (isFrameMetric) {
        metaElement.textContent = frameSampleCopy(
          physicalCheckpoint,
          metricKey,
          marker,
          scenario
        );
      } else if (label === ROOM_ENTRY_SUMMARY && metricKey === "transition_ms") {
        metaElement.textContent = `Médiane de ${physicalCheckpoint?.cycle_count || 0} ouvertures · ${severityCopy(marker)}`;
      } else {
        metaElement.textContent = severityCopy(marker);
      }
    });
  }

  function worstMarker(markers) {
    const order = { missing: 0, baseline: 1, normal: 2, warning: 3, critical: 4 };
    return Object.values(markers).sort(
      (left, right) => order[right?.severity || "missing"] - order[left?.severity || "missing"]
    )[0];
  }

  function updateVerdict(latest, latestMarkers) {
    const verdict = elements.verdict;
    verdict.classList.remove("stable", "critical");
    elements["latest-date"].textContent = latest.date;
    elements["latest-sha"].innerHTML = `<a href="${latest.commit.url}">${latest.commit.sha.slice(0, 9)} ↗</a>`;
    if (!isProfileRecord(latest)) {
      elements["overall-status"].textContent = "Mesure profile en attente";
      elements["overall-detail"].textContent = "Le point existant vient d’un APK debug et reste volontairement exclu des comparaisons.";
      return;
    }
    const worst = worstMarker(latestMarkers);
    if (worst?.severity === "critical") {
      verdict.classList.add("critical");
      elements["overall-status"].textContent = "Dégradation détectée";
      elements["overall-detail"].textContent = "Au moins un signal est dégradé de 20 % ou plus face aux sept nuits précédentes.";
    } else if (worst?.severity === "warning") {
      elements["overall-status"].textContent = "À surveiller";
      elements["overall-detail"].textContent = "Au moins un signal est dégradé de 10 % ou plus. Vérifiez le commit et la prochaine nuit.";
    } else if (worst?.severity === "normal") {
      verdict.classList.add("stable");
      elements["overall-status"].textContent = "Performances stables";
      elements["overall-detail"].textContent = "Aucun signal principal ne dépasse le seuil de dégradation de 10 %.";
    } else {
      elements["overall-status"].textContent = "Historique en construction";
      elements["overall-detail"].textContent = "Sept nuits précédentes sont nécessaires avant d’émettre un diagnostic automatique.";
    }
  }

  function inspectionValue(record, metric, selection) {
    if (!isProfileRecord(record)) return "Non comparable · ancien APK debug";
    const value = metricValue(record, metric, selection.scenario, selection.label);
    if (value != null) return metric.format(value);
    if (metric.source !== "physical") return "Non mesuré";
    if (selection.metricKey === "fps" && !selection.scenario.includes("scroll")) {
      return "Non applicable sur une transition";
    }
    const selected = checkpoint(
      record,
      "physical",
      selection.scenario,
      selection.label
    );
    if (["fps", "jank_rate"].includes(selection.metricKey) && !hasEnoughFrames(selected)) {
      return `Données insuffisantes (${selected?.frame_count || 0}/${MIN_FRAME_SAMPLE} frames)`;
    }
    return "Non mesuré";
  }

  function inspectPoint(day) {
    const record = state.records.find(item => item.date === day);
    if (!record) return;
    const scenario = elements["scenario-select"].value;
    const label = elements["checkpoint-select"].value;
    const previous = [...state.records].reverse().find(item => item.date < day);
    const compareUrl = previous
      ? `https://github.com/linagora/twake-on-matrix/compare/${previous.commit.sha}...${record.commit.sha}`
      : null;
    const metricDetails = Object.entries(METRICS).map(([metricKey, metric]) => {
      const value = inspectionValue(record, metric, { scenario, label, metricKey });
      return `<dl><dt>${metric.label}</dt><dd>${value}</dd></dl>`;
    }).join("");
    elements["inspection-title"].textContent = `${day} · ${checkpointLabel(label)}`;
    elements["inspection-values"].innerHTML = `
      ${metricDetails}
      <dl><dt>Commit</dt><dd><a href="${record.commit.url}">${record.commit.sha.slice(0, 9)} ↗</a></dd></dl>
      <dl><dt>Preuves</dt><dd><a href="${record.run.url}">Run Actions ${record.run.id} ↗</a>${compareUrl ? ` · <a href="${compareUrl}">Comparer ↗</a>` : ""}</dd></dl>`;
  }

  function render() {
    const scenario = elements["scenario-select"].value;
    const label = elements["checkpoint-select"].value;
    if (!state.records.length || !scenario || !label) return;
    const days = calendarDays();
    const recordsByDay = new Map(state.records.map(record => [record.date, record]));
    const selection = { scenario, label };
    const datasets = Object.keys(METRICS).map(
      metricKey => buildDataset(metricKey, days, recordsByDay, selection)
    );
    renderChart(days, datasets);

    const latest = state.records.at(-1);
    const latestMarkers = Object.fromEntries(datasets.map(dataset => [
      dataset.metricKey,
      dataset.markers[days.indexOf(latest.date)],
    ]));
    updateMetricCards(latest, scenario, label, latestMarkers);
    updateVerdict(latest, latestMarkers);
  }

  function validateIndex(index) {
    if (index.schema_version !== 1 || !Array.isArray(index.entries)) {
      throw new Error("Format de données non pris en charge");
    }
  }

  function markDatasetReady() {
    elements["history-depth"].textContent = `${state.index.entries.length} nuit${state.index.entries.length > 1 ? "s" : ""}`;
    elements["status-light"].classList.add("ready");
    elements["status-label"].textContent = "Mesures disponibles";
    elements["status-meta"].textContent = `Mise à jour ${state.index.updated_at || state.records.at(-1).generated_at}`;
  }

  function showDatasetError(error) {
    elements["status-light"].classList.add("error");
    elements["status-label"].textContent = "Mesures indisponibles";
    elements["status-meta"].textContent = error.message;
    elements["overall-status"].textContent = "Impossible d’analyser les performances";
    elements["overall-detail"].textContent = "La page se remplira après une publication nightly réussie.";
    elements["inspection-title"].textContent = "Aucun historique disponible";
    elements["inspection-values"].innerHTML = `<p>${error.message}</p>`;
  }

  async function fetchIndex() {
    const response = await fetch("data/index.json", { cache: "no-store" });
    if (!response.ok) throw new Error(`L’index des mesures répond HTTP ${response.status}`);
    const index = await response.json();
    validateIndex(index);
    return index;
  }

  async function load() {
    state.index = await fetchIndex();
    await loadSelectedRecords();
    if (!state.records.length) throw new Error("L’historique nightly est vide");
    markDatasetReady();
    populateScenarios();
  }

  async function reloadSelectedRange() {
    await loadSelectedRecords();
    populateScenarios();
  }

  function reportRangeError(error) {
    elements["status-light"].classList.add("error");
    elements["status-label"].textContent = "Mesures indisponibles";
    elements["status-meta"].textContent = error.message;
  }

  elements["range-select"].addEventListener("change", () => {
    reloadSelectedRange().catch(reportRangeError);
  });
  elements["scenario-select"].addEventListener("change", populateCheckpoints);
  elements["checkpoint-select"].addEventListener("change", render);
  load().catch(showDatasetError);
})();
