import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.perf.update_history import (
    HistoryError,
    RecordMetadata,
    build_daily_record,
    update_history,
    write_summary,
)


def checkpoint(samples=3, value=100.0):
    return {
        "scenario": "nav_cycles",
        "label": "room_entered",
        "sample_count": samples,
        "rss_bytes": value,
        "rss_bytes_stddev": 2.5,
        "rss_bytes_range": 5.0,
        "build_p95_us": 2_000.0,
    }


def record(day="2026-07-22", sha="abc123"):
    metadata = RecordMetadata(
        day=day,
        generated_at=f"{day}T00:15:00Z",
        repository="linagora/twake-on-matrix",
        sha=sha,
        run_id="12345",
        flutter_version="3.38.9",
    )
    return build_daily_record(
        [checkpoint()],
        [checkpoint(samples=1, value=120.0)],
        metadata,
    )


class BuildDailyRecordTest(unittest.TestCase):
    def test_preserves_aggregates_and_describes_sources(self):
        daily = record()

        self.assertEqual(daily["schema_version"], 1)
        self.assertEqual(daily["memory"]["aggregation"], "median")
        self.assertEqual(daily["physical"]["aggregation"], "single_run")
        self.assertEqual(daily["memory"]["checkpoints"][0]["rss_bytes_stddev"], 2.5)
        self.assertEqual(daily["memory"]["checkpoints"][0]["rss_bytes_range"], 5.0)
        self.assertEqual(daily["environment"]["virtual_device"]["runs"], 3)
        self.assertEqual(daily["environment"]["physical_device"]["runs"], 1)

    def test_rejects_invalid_virtual_aggregation(self):
        cases = (
            ("partial samples", {"sample_count": 2}, "at least 3 required"),
            ("invalid metric", {"rss_bytes": "unknown"}, "finite number"),
            (
                "non-numeric samples",
                {"sample_count": "3"},
                "sample_count must be a finite number",
            ),
        )
        metadata = RecordMetadata(
            day="2026-07-22",
            generated_at="2026-07-22T00:15:00Z",
            repository="linagora/twake-on-matrix",
            sha="abc123",
            run_id="12345",
            flutter_version="3.38.9",
        )
        for name, changes, expected_error in cases:
            with self.subTest(name=name):
                invalid = checkpoint()
                invalid.update(changes)
                with self.assertRaisesRegex(HistoryError, expected_error):
                    build_daily_record(
                        [invalid],
                        [checkpoint(samples=1)],
                        metadata,
                    )

    def test_rejects_invalid_record_date(self):
        metadata = RecordMetadata(
            day="not-a-date",
            generated_at="2026-07-22T00:15:00Z",
            repository="linagora/twake-on-matrix",
            sha="abc123",
            run_id="12345",
            flutter_version="3.38.9",
        )

        with self.assertRaisesRegex(HistoryError, "Invalid UTC date"):
            build_daily_record(
                [checkpoint()],
                [checkpoint(samples=1)],
                metadata,
            )


class UpdateHistoryTest(unittest.TestCase):
    def test_adds_points_in_chronological_order(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            data_directory = Path(temporary_directory)
            update_history(data_directory, record("2026-07-23", "newer"))
            index = update_history(data_directory, record("2026-07-22", "older"))

            self.assertEqual(
                [entry["date"] for entry in index["entries"]],
                ["2026-07-22", "2026-07-23"],
            )

    def test_replaces_same_day_without_duplicate(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            data_directory = Path(temporary_directory)
            update_history(data_directory, record(sha="first"))
            index = update_history(data_directory, record(sha="replacement"))

            self.assertEqual(len(index["entries"]), 1)
            self.assertEqual(index["entries"][0]["sha"], "replacement")
            daily = json.loads((data_directory / "2026-07-22.json").read_text())
            self.assertEqual(daily["commit"]["sha"], "replacement")

    def test_rejects_future_index_schema(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            data_directory = Path(temporary_directory)
            (data_directory / "index.json").write_text(
                json.dumps({"schema_version": 2, "entries": []})
            )

            with self.assertRaisesRegex(HistoryError, "Unsupported history index schema"):
                update_history(data_directory, record())

    def test_rejects_malformed_index_entry(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            data_directory = Path(temporary_directory)
            (data_directory / "index.json").write_text(
                json.dumps({"schema_version": 1, "entries": [{"date": "2026-07-21"}]})
            )

            with self.assertRaisesRegex(HistoryError, "Malformed history index entry"):
                update_history(data_directory, record())

    def test_rejects_missing_daily_record(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            data_directory = Path(temporary_directory)
            (data_directory / "index.json").write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "entries": [
                            {
                                "date": "2026-07-21",
                                "file": "2026-07-21.json",
                                "sha": "previous",
                                "run_id": "100",
                            }
                        ],
                    }
                )
            )

            with self.assertRaisesRegex(HistoryError, "Cannot read valid JSON"):
                update_history(data_directory, record())

    def test_summary_marks_regression_against_seven_prior_points(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            data_directory = Path(temporary_directory)
            for day in range(1, 8):
                daily = record(f"2026-07-{day:02d}", f"baseline-{day}")
                update_history(data_directory, daily)

            regressed = record("2026-07-08", "regressed")
            regressed["memory"]["checkpoints"][0]["rss_bytes"] = 125.0
            index = update_history(data_directory, regressed)
            summary_path = data_directory / "summary.md"
            preview_url = "https://example.test/performance-preview/"
            with patch.dict(os.environ, {"PERF_DASHBOARD_URL": preview_url}):
                write_summary(summary_path, data_directory, index, regressed)

            summary = summary_path.read_text()
            self.assertIn("critical", summary)
            self.assertIn("+25.0%", summary)
            self.assertIn("Download the consolidated JSON artifact", summary)
            self.assertIn(preview_url, summary)


if __name__ == "__main__":
    unittest.main()
