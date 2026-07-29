import json
import tempfile
import unittest
from pathlib import Path

from scripts.perf.compute_median import _load_requirements, compute_median


class ComputeMedianTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary_directory.name)
        self.logs = []
        for index, fps in enumerate((58.0, 60.0, 62.0), start=1):
            path = self.directory / f"run-{index}.log"
            path.write_text(
                "PERF_METRIC | web_navigation | room_opened"
                f" | fps={fps} | transition_ms={100 + index}\n",
                encoding="utf-8",
            )
            self.logs.append(str(path))

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def test_load_requirements_combines_common_and_checkpoint_metrics(self) -> None:
        manifest = self.directory / "requirements.json"
        manifest.write_text(
            json.dumps(
                {
                    "common_metrics": ["fps", "frame_count"],
                    "checkpoints": [
                        {
                            "scenario": "nav_cycles",
                            "label": "room_enter_cycle1",
                            "extra_metrics": ["transition_ms"],
                            "excluded_metrics": ["fps"],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )

        self.assertEqual(
            _load_requirements(str(manifest)),
            {
                ("nav_cycles", "room_enter_cycle1"): {
                    "frame_count",
                    "transition_ms",
                }
            },
        )

    def test_default_output_keeps_existing_contract(self) -> None:
        output = self.directory / "median.json"
        compute_median(self.logs, str(output))

        checkpoint = json.loads(output.read_text(encoding="utf-8"))[0]
        self.assertEqual(checkpoint["fps"], 60.0)
        self.assertNotIn("fps_values", checkpoint)

    def test_optional_raw_values_are_kept_with_aggregates(self) -> None:
        output = self.directory / "median.json"
        compute_median(self.logs, str(output), include_values=True)

        checkpoint = json.loads(output.read_text(encoding="utf-8"))[0]
        self.assertEqual(checkpoint["sample_count"], 3)
        self.assertEqual(checkpoint["fps"], 60.0)
        self.assertEqual(checkpoint["fps_values"], [58.0, 60.0, 62.0])
        self.assertEqual(checkpoint["fps_range"], 4.0)
        self.assertEqual(checkpoint["fps_stddev"], 2.0)

    def test_optional_metric_does_not_reduce_checkpoint_sample_count(self) -> None:
        Path(self.logs[1]).write_text(
            "PERF_METRIC | web_navigation | room_opened"
            " | transition_ms=102\n",
            encoding="utf-8",
        )
        output = self.directory / "median.json"

        compute_median(self.logs, str(output), include_values=True)

        checkpoint = json.loads(output.read_text(encoding="utf-8"))[0]
        self.assertEqual(checkpoint["sample_count"], 3)
        self.assertEqual(checkpoint["fps"], 60.0)
        self.assertEqual(checkpoint["fps_sample_count"], 2)
        self.assertEqual(checkpoint["fps_values"], [58.0, 62.0])
        self.assertEqual(checkpoint["transition_ms_sample_count"], 3)
        self.assertEqual(checkpoint["transition_ms_values"], [101.0, 102.0, 103.0])

    def test_expected_samples_rejects_incomplete_metric(self) -> None:
        Path(self.logs[1]).write_text(
            "PERF_METRIC | web_navigation | room_opened"
            " | transition_ms=102\n",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(
            ValueError,
            r"web_navigation/room_opened/fps has 2 sample\(s\); expected 3",
        ):
            compute_median(
                self.logs,
                str(self.directory / "median.json"),
                expected_samples=3,
            )

    def test_expected_samples_rejects_duplicate_repetition(self) -> None:
        combined_log = self.directory / "combined.log"
        combined_log.write_text(
            "PERF_METRIC | web_navigation | room_opened | run=r1 | fps=58\n"
            "PERF_METRIC | web_navigation | room_opened | run=r1 | fps=59\n"
            "PERF_METRIC | web_navigation | room_opened | run=r2 | fps=60\n",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(
            ValueError,
            r"duplicate sample.*web_navigation/room_opened.*r1",
        ):
            compute_median(
                [str(combined_log)],
                str(self.directory / "median.json"),
                expected_samples=3,
            )

    def test_expected_samples_rejects_two_android_samples_from_one_file(self) -> None:
        Path(self.logs[0]).write_text(
            "PERF_METRIC | nav_cycles | room_enter_cycle1 | run=r1 | fps=58\n"
            "PERF_METRIC | nav_cycles | room_enter_cycle1 | run=r2 | fps=59\n",
            encoding="utf-8",
        )
        Path(self.logs[1]).write_text(
            "PERF_METRIC | nav_cycles | room_enter_cycle1 | run=r3 | fps=60\n",
            encoding="utf-8",
        )
        Path(self.logs[2]).write_text("", encoding="utf-8")

        with self.assertRaisesRegex(
            ValueError,
            r"duplicate sample.*nav_cycles/room_enter_cycle1.*source 0",
        ):
            compute_median(
                self.logs,
                str(self.directory / "median.json"),
                expected_samples=3,
            )

    def test_requirements_reject_metric_absent_from_every_repetition(self) -> None:
        for index, path in enumerate(self.logs, start=1):
            Path(path).write_text(
                "PERF_METRIC | web_navigation | room_opened"
                f" | transition_ms={100 + index}\n",
                encoding="utf-8",
            )

        with self.assertRaisesRegex(
            ValueError,
            r"web_navigation/room_opened/fps is missing",
        ):
            compute_median(
                self.logs,
                str(self.directory / "median.json"),
                expected_samples=3,
                requirements={
                    ("web_navigation", "room_opened"): {
                        "fps",
                        "transition_ms",
                    },
                },
            )

    def test_requirements_reject_checkpoint_absent_from_every_repetition(self) -> None:
        with self.assertRaisesRegex(
            ValueError,
            r"required checkpoint web_navigation/scroll_completed is missing",
        ):
            compute_median(
                self.logs,
                str(self.directory / "median.json"),
                expected_samples=3,
                requirements={
                    ("web_navigation", "room_opened"): {"fps"},
                    ("web_navigation", "scroll_completed"): {"fps"},
                },
            )

    def test_missing_checkpoint_reduces_sample_count(self) -> None:
        Path(self.logs[1]).write_text("", encoding="utf-8")
        output = self.directory / "median.json"

        compute_median(self.logs, str(output))

        checkpoint = json.loads(output.read_text(encoding="utf-8"))[0]
        self.assertEqual(checkpoint["sample_count"], 2)


if __name__ == "__main__":
    unittest.main()
