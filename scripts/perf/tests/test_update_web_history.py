import tempfile
import unittest
from pathlib import Path

from scripts.perf.update_web_history import (
    WebHistoryError,
    WebMetadata,
    build_daily_record,
    parse_environment,
    update_history,
)


def checkpoint(fps: float = 60.0) -> dict:
    result = {
        "scenario": "web_navigation",
        "label": "room_opened",
        "sample_count": 3,
    }
    metrics = {
        "frame_count": 60.0,
        "fps": fps,
        "frame_interval_p95_ms": 17.0,
        "frame_interval_p99_ms": 18.0,
        "slow_frame_rate": 0.02,
        "long_task_total_ms": 10.0,
    }
    for key, value in metrics.items():
        result[key] = value
        result[f"{key}_values"] = [value - 1, value, value + 1]
        result[f"{key}_stddev"] = 1.0
        result[f"{key}_range"] = 2.0
    return result


def metadata(day: str = "2026-07-24", sha: str = "abc") -> WebMetadata:
    return WebMetadata(
        day=day,
        generated_at=f"{day}T02:30:00Z",
        repository="linagora/twake-on-matrix",
        sha=sha,
        run_id="123",
        flutter_version="3.38.9",
        patrol_version="4.3.1",
        runner_image="ubuntu-24.04",
    )


ENVIRONMENT = {
    "user_agent": "Mozilla/5.0 HeadlessChrome/140.0.1.2 Safari/537.36",
    "viewport": {"width": 1440, "height": 900, "device_pixel_ratio": 1},
    "renderer": "canvas",
}


class UpdateWebHistoryTest(unittest.TestCase):
    def test_builds_versioned_record_with_environment_and_raw_values(self) -> None:
        record = build_daily_record([checkpoint()], ENVIRONMENT, metadata())

        self.assertEqual(record["schema_version"], 1)
        self.assertEqual(record["web"]["aggregation"], "median")
        self.assertEqual(record["web"]["repetitions"], 3)
        self.assertEqual(record["environment"]["browser"]["version"], "140.0.1.2")
        self.assertEqual(record["web"]["checkpoints"][0]["fps_values"], [59, 60, 61])

    def test_rejects_partial_or_invalid_result(self) -> None:
        partial = checkpoint()
        partial["sample_count"] = 2
        with self.assertRaises(WebHistoryError):
            build_daily_record([partial], ENVIRONMENT, metadata())

        missing = checkpoint()
        del missing["fps_values"]
        with self.assertRaises(WebHistoryError):
            build_daily_record([missing], ENVIRONMENT, metadata())

    def test_history_is_sorted_and_same_day_is_replaced(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            data = Path(directory)
            later = build_daily_record([checkpoint()], ENVIRONMENT, metadata())
            earlier = build_daily_record(
                [checkpoint(55.0)],
                ENVIRONMENT,
                metadata("2026-07-23", "older"),
            )
            update_history(data, later)
            index = update_history(data, earlier)
            self.assertEqual(
                [entry["date"] for entry in index["entries"]],
                ["2026-07-23", "2026-07-24"],
            )

            replacement = build_daily_record(
                [checkpoint(61.0)],
                ENVIRONMENT,
                metadata("2026-07-24", "replacement"),
            )
            index = update_history(data, replacement)
            self.assertEqual(len(index["entries"]), 2)
            self.assertEqual(index["entries"][1]["sha"], "replacement")

    def test_rejects_future_index_schema(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            data = Path(directory)
            (data / "index.json").write_text(
                '{"schema_version": 2, "entries": []}',
                encoding="utf-8",
            )
            with self.assertRaises(WebHistoryError):
                update_history(
                    data,
                    build_daily_record([checkpoint()], ENVIRONMENT, metadata()),
                )

    def test_parses_environment_from_prefixed_log_line(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "web.log"
            log.write_text(
                'browser: PERF_WEB_ENV | {"user_agent":"Chrome/140.0",'
                '"viewport":{"width":1440,"height":900,"device_pixel_ratio":1},'
                '"renderer":"canvas"}\n',
                encoding="utf-8",
            )
            self.assertEqual(parse_environment(log)["renderer"], "canvas")


if __name__ == "__main__":
    unittest.main()
