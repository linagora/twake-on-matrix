import json
import tempfile
import unittest
from pathlib import Path

from scripts.perf.update_history import (
    HistoryError,
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
    return build_daily_record(
        [checkpoint()],
        [checkpoint(samples=1, value=120.0)],
        day=day,
        generated_at=f"{day}T00:15:00Z",
        repository="linagora/twake-on-matrix",
        sha=sha,
        run_id="12345",
        flutter_version="3.38.9",
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

    def test_rejects_partial_virtual_aggregation(self):
        with self.assertRaisesRegex(HistoryError, "at least 3 required"):
            build_daily_record(
                [checkpoint(samples=2)],
                [checkpoint(samples=1)],
                day="2026-07-22",
                generated_at="2026-07-22T00:15:00Z",
                repository="linagora/twake-on-matrix",
                sha="abc123",
                run_id="12345",
                flutter_version="3.38.9",
            )

    def test_rejects_invalid_metric(self):
        invalid = checkpoint()
        invalid["rss_bytes"] = "unknown"
        with self.assertRaisesRegex(HistoryError, "finite number"):
            build_daily_record(
                [invalid],
                [checkpoint(samples=1)],
                day="2026-07-22",
                generated_at="2026-07-22T00:15:00Z",
                repository="linagora/twake-on-matrix",
                sha="abc123",
                run_id="12345",
                flutter_version="3.38.9",
            )

    def test_rejects_non_numeric_sample_count(self):
        invalid = checkpoint()
        invalid["sample_count"] = "3"
        with self.assertRaisesRegex(HistoryError, "sample_count must be a finite number"):
            build_daily_record(
                [invalid],
                [checkpoint(samples=1)],
                day="2026-07-22",
                generated_at="2026-07-22T00:15:00Z",
                repository="linagora/twake-on-matrix",
                sha="abc123",
                run_id="12345",
                flutter_version="3.38.9",
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
            write_summary(summary_path, data_directory, index, regressed)

            summary = summary_path.read_text()
            self.assertIn("critical", summary)
            self.assertIn("+25.0%", summary)
            self.assertIn("Download the consolidated JSON artifact", summary)


if __name__ == "__main__":
    unittest.main()
